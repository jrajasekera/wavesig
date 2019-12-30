class SharedfileController < ApplicationController


  def show
    #@uploadedfile = Uploadedfile.find_by id: params[:file_id]
    #
    #@audio_file =  @uploadedfile.audio_file
    #
    ## redirect user if they are not the owner
    #if current_user.id != @uploadedfile.user_id
    #  redirect_to user_dashboard_path(current_user.id)
    #end

  end

  def edit_share
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    @shared_records = @uploadedfile.sharedfiles


    if current_user.id != @uploadedfile.user_id
      redirect_to user_dashboard_path(current_user.id)
    end
  end

  def share
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id == @uploadedfile.user_id
      pp '--------------------------------------------------'
      pp 'share with -> ' + params[:share_email]

      @shared_user_email_param = params[:share_email].downcase

      @shared_user = User.find_by email: @shared_user_email_param

      if @shared_user.nil?
        flash[:alert] = @shared_user_email_param + ' is not a current user.'
      else
        newShare = Sharedfile.new :user_id => @shared_user.id, :uploadedfile_id => @uploadedfile.id

        newShare.audio_file.attach io: StringIO.new(@uploadedfile.audio_file.download),
                                 filename: @uploadedfile.audio_file.filename,
                                 content_type: @uploadedfile.audio_file.content_type

        if newShare.save
          flash[:notice] = 'Shared file with ' + @shared_user.email + '!'
        else
          flash[:alert] = 'Error sharing file with ' + @shared_user.email + '!'
        end

      end

    end

    redirect_to edit_share_file_path id: @uploadedfile.id

  end

  def remove_user
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]
    shared_user = User.find params[:user_id]

    if Sharedfile.find_by(uploadedfile_id: @uploadedfile, user_id: params[:user_id]).destroy
      flash[:notice] = 'Unshared file with ' + shared_user.email + '!'
    else
      flash[:alert] = 'Error unsharing file with ' + shared_user.email + '!'
    end

    redirect_to edit_share_file_path id: @uploadedfile.id
  end

  def uploadedfile_params
    params.require(:uploadedfile).permit(:fileName, :description, :audio_file)
  end

end