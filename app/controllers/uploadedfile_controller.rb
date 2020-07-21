class UploadedfileController < ApplicationController
  before_action :verify_correct_user, only: [:delete, :find_origin, :find_origin_results, :find_origin_form]

  def verify_correct_user
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id != @uploadedfile.user_id
      flash[:alert] = 'You do not have access to that file.'
      redirect_to user_dashboard_path(current_user.id)
    end
  end

  def new
    @uploadedfile = Uploadedfile.new
  end

  def create
    @uploadedfile = Uploadedfile.new(uploadedfile_params)

    @uploadedfile.user_id = current_user.id
    pp @uploadedfile.audio_file

    if @uploadedfile.save
      flash[:notice] = 'File uploaded successfully!'
      redirect_to show_upload_file_path(@uploadedfile.id)
    else
      @uploadedfile.audio_file.purge
      flash.now[:alert] = "File upload error! " + @uploadedfile.errors.details.values[0].map{ |item| item[:error]}.join(" ")
      render "new"
    end

  end

  def show
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id == @uploadedfile.user_id
      # owner of file
      @audio_file =  @uploadedfile.audio_file
    else
      sharedfile = @uploadedfile.sharedfiles.find {|sharedfile| sharedfile.user_id == current_user.id}

      if !sharedfile.nil?
        @audio_file =  sharedfile.audio_file
      else
        flash[:alert] = 'You do not have access to that file.'
        redirect_to user_dashboard_path(current_user.id)
      end
    end

  end

  def graph
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id == @uploadedfile.user_id
      # owner of file
      @audio_file =  @uploadedfile.audio_file
      @data = helpers.audio_file_to_graph_data(@uploadedfile)

    else
      sharedfile = @uploadedfile.sharedfiles.find {|sharedfile| sharedfile.user_id == current_user.id}

      if !sharedfile.nil?
        @audio_file =  sharedfile.audio_file
        @data = helpers.audio_file_to_graph_data(sharedfile)
      else
        flash[:alert] = 'You do not have access to that file.'
        redirect_to user_dashboard_path(current_user.id)
      end
    end

  end

  def delete
    # delete shared copies
    @uploadedfile.sharedfiles.each do |shared_file|
      shared_file.audio_file.purge
      if not shared_file.destroy
        flash.now[:alert] = 'Error deleting associated shared files!'
      end
    end

    # delete attachment
    @uploadedfile.audio_file.purge
    #@uploadedfile.audio_file.purge_later ASYNC

    #delete file row
    if @uploadedfile.destroy
      flash[:notice] = 'File Deleted!'
      redirect_to user_dashboard_path(current_user.id)
    else
      flash.now[:alert] = 'Error deleting file! Please try again.'
    end
  end

  def uploadedfile_params
    params.require(:uploadedfile).permit(:fileName, :description, :audio_file)
  end

  def leaker_file_params
    params.require(:leaker_file).permit(:origin_audio_file)
  end

  def find_origin_form
    @user = current_user
    @file = Uploadedfile.find params[:file_id]

  end

  def find_origin
    @original_file = @uploadedfile

    leaker_file = leaker_file_params[:origin_audio_file]



    if leaker_file.nil?
      flash[:alert] = 'No file attached.'
    else
      leaker_file_io = leaker_file.tempfile.to_io
      if(leaker_file_io.size > (Uploadedfile::MAX_UPLOAD_FILE_SIZE * 1.3) )
        flash[:alert] = "File has to be less than #{(Uploadedfile::MAX_UPLOAD_FILE_SIZE * 1.3)/1.megabytes} MB."
      else
        leaker_file_tempfile_path = leaker_file.tempfile.path
        leaker_file_path = "#{leaker_file_tempfile_path}_file"
        IO.copy_stream(leaker_file_tempfile_path,leaker_file_path)
        findOriginJob =  FindFileOriginJob.perform_later(@uploadedfile, leaker_file_path)
        runningJob = RunningJob.new :user_id => current_user.id,
                                    :job_id => findOriginJob.job_id,
                                    :job_type => "find_origin",
                                    :target_type => "Uploadedfile",
                                    :target_id => @uploadedfile.id
        runningJob.save

      end
    end
    redirect_to find_origin_form_path(@uploadedfile.id)
  end

  def find_origin_results
    @originJobs = RunningJob.where("user_id = ? AND job_type = ? AND target_id = ?", current_user.id, "find_origin", @uploadedfile.id)
    @originResults =  @uploadedfile.find_origin_results.order('created_at DESC').map { |result| [
        result.created_at.strftime("%m/%d/%Y %I:%M %p"),
        (result.origin_user_id.nil? ? "Unknown" : (User.find(result.origin_user_id).fullName))
    ] }
    render partial: "find_origin_results"
  end

end