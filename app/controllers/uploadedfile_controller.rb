class UploadedfileController < ApplicationController

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
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    @audio_file =  @uploadedfile.audio_file

    # redirect user if they are not the owner
    if current_user.id != @uploadedfile.user_id
      redirect_to user_dashboard_path(current_user.id)
    end

  end

  def delete
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id == @uploadedfile.user_id
      # TODO delete shared files?

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
  end

  def uploadedfile_params
    params.require(:uploadedfile).permit(:fileName, :description, :audio_file)
  end

end