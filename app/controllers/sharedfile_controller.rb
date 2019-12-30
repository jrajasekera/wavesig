class SharedfileController < ApplicationController
  before_action :verify_correct_user, except: [:show]

  def verify_correct_user
    @uploadedfile = Uploadedfile.find_by id: params[:file_id]

    if current_user.id != @uploadedfile.user_id
      flash[:alert] = 'You do not have access to that file.'
      redirect_to user_dashboard_path(current_user.id)
    end
  end

  def show


  end

  def edit_share
    @shared_records = @uploadedfile.sharedfiles
  end

  def share
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

    redirect_to edit_share_file_path id: @uploadedfile.id
  end

  def remove_user
    #@uploadedfile = Uploadedfile.find_by id: params[:file_id]
    shared_user = User.find params[:user_id]

    shared_file = Sharedfile.find_by(uploadedfile_id: @uploadedfile, user_id: params[:user_id])
    shared_file.audio_file.purge

    if shared_file.destroy
      flash[:notice] = 'Unshared file with ' + shared_user.email + '!'
    else
      flash[:alert] = 'Error unsharing file with ' + shared_user.email + '!'
    end

    redirect_to edit_share_file_path id: @uploadedfile.id
  end

end