class UploadedfileController < ApplicationController
  before_action :verify_correct_user, only: [:delete, :find_origin]

  MAX_UPLOAD_FILE_SIZE = 50.megabytes

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

    # validate for correct file type and size
    if !@uploadedfile.audio_file.attachment.nil? &&
        @uploadedfile.audio_file.content_type == 'audio/x-wav' &&
        @uploadedfile.audio_file.byte_size <= MAX_UPLOAD_FILE_SIZE

      @uploadedfile.user_id = current_user.id
      pp @uploadedfile.audio_file

      if @uploadedfile.save
        flash[:notice] = 'File uploaded successfully!'
        redirect_to show_upload_file_path(@uploadedfile.id)
      else
        flash.now[:alert] = 'File upload error! Please try again.'
        render "new"
      end
    else
      flash.now[:alert] = "File upload error! File must be in wav format and with a size of less than #{MAX_UPLOAD_FILE_SIZE/1.megabytes} MB."
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
    leaker_file = leaker_file_params[:origin_audio_file].tempfile.to_io

    @leaker = helpers.find_leak_source(@original_file, leaker_file)

    if @leaker == nil
      @leaker_email = "Unknown"
    else
      @leaker_email = @leaker.email
    end

  end

end