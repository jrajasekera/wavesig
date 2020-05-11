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
    @shareable_users = current_user.friends - @shared_records.map { |record| record.user }
  end

  def share
    @shared_user_id = params[:users]

    @shared_user_id.each do |userId|
      @shared_user = User.find userId

      if @shared_user.nil?
        flash[:alert] = 'You selected a non-active user.'
      elsif @shared_user == current_user
        flash[:alert] = 'You cannot share a file with yourself.'
      else
        watermark = helpers.generate_watermark
        newShare = Sharedfile.new :user_id => @shared_user.id, :uploadedfile_id => @uploadedfile.id, :watermark => watermark

        newShare.audio_file.attach io: File.open(helpers.embed_watermark(@uploadedfile, watermark)),
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

  # def share
  #   @shared_user_email_param = params[:share_email].downcase
  #   @shared_user = User.find_by email: @shared_user_email_param
  #
  #   if @shared_user.nil?
  #     flash[:alert] = @shared_user_email_param + ' is not a current user.'
  #   elsif @shared_user == current_user
  #     flash[:alert] = @shared_user_email_param + ' you cannot share a file with yourself.'
  #   else
  #     watermark = helpers.generate_watermark
  #     newShare = Sharedfile.new :user_id => @shared_user.id, :uploadedfile_id => @uploadedfile.id, :watermark => watermark
  #
  #     #newShare.audio_file.attach io: StringIO.new(helpers.embed_watermark(@uploadedfile)),
  #     newShare.audio_file.attach io: File.open(helpers.embed_watermark(@uploadedfile, watermark)),
  #                              filename: @uploadedfile.audio_file.filename,
  #                              content_type: @uploadedfile.audio_file.content_type
  #
  #     if newShare.save
  #       flash[:notice] = 'Shared file with ' + @shared_user.email + '!'
  #     else
  #       flash[:alert] = 'Error sharing file with ' + @shared_user.email + '!'
  #     end
  #
  #   end
  #
  #   redirect_to edit_share_file_path id: @uploadedfile.id
  # end

  def remove_user
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