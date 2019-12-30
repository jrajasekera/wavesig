class UploadedfileController < ApplicationController
  before_action :verify_correct_user, only: [:show, :delete]

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
      flash.now[:alert] = 'File upload error! Please try again.'
      render "new"
    end

  end

  def show
    @audio_file =  @uploadedfile.audio_file

    # redirect user if they are not the owner
    if current_user.id != @uploadedfile.user_id
      redirect_to user_dashboard_path(current_user.id)
    end

  end

  def delete
    # delete shared copies
    @uploadedfile.sharedfiles.each do |shared_file|
      shared_file.audio_file.purge
      if not shared_file.destroy
        flash.now[:alert] = 'Error associated shared files!'
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

end