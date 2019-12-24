class UploadedfileController < ApplicationController
  # TODO make sure current user is the one uploading

  def new
    @uploadedfile = Uploadedfile.new
  end

  def create
    pp "___________________CREATE METHOD REACHED___________________________________"

    user_id = params[:user]
    @user = User.find_by id: user_id

    @uploadedfile = Uploadedfile.new(uploadedfile_params)
    @uploadedfile.user_id = @user.id

    if @uploadedfile.save
      flash.now[:notice] = 'File uploaded successfully!'
      pp "SUCCESS"
      #redirect somewhere
    else
      flash.now[:alert] = 'File upload error!'
      render "new"
    end

  end

  def uploadedfile_params
    params.require(:uploadedfile).permit(:fileName, :description, :audio_file)
  end


end