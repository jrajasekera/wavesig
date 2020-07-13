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
    # @shared_records = @uploadedfile.sharedfiles
    # @shareable_users = current_user.friends - @shared_records.map { |record| record.user }
  end

  def share
    @shared_user_id = params[:users]

    @shared_user_id.each do |userId|
      @shared_user = User.find userId

      if @shared_user.nil?
        flash[:alert] = 'You selected a non-active user.'
      elsif @shared_user == current_user
        flash[:alert] = 'You cannot share a file with yourself.'
      elsif !current_user.friend_with? @shared_user
        flash[:alert] = 'You can only share files with friends.'
      elsif @uploadedfile.sharedfiles.map { |sharedfile| sharedfile.user }.include? @shared_user
        flash[:alert] = "You have already shared this file with #{@shared_user.fname} #{@shared_user.lname}."
      else
        shareJob = ShareFileJob.perform_later(@shared_user, current_user, @uploadedfile)

        runningJob = RunningJob.new :user_id => current_user.id, :job_id => shareJob.job_id, :job_type => "share", :target_type => "User", :target_id => @shared_user.id
        if runningJob.save
          flash[:notice] = 'Your file is being processed and shared!'
        else
          flash[:alert] = 'Your file is being processed and shared. Refresh the page in a few minutes.'
        end
      end

    end

    redirect_to edit_share_file_path id: @uploadedfile.id
  end

  def shared_users
    @shared_records = @uploadedfile.sharedfiles
    @shareable_users = current_user.friends - @shared_records.map { |record| record.user }
    # byebug
    userJobs = RunningJob.where("user_id = ? AND job_type = ?", current_user.id, "share")
    @share_users = userJobs.map { |job| User.find(job.target_id) }

    # @share_users = [User.find(1),User.find(2)]
    # rails generate migration AddTargetsToRunning_Jobs target_type:string target_id:bigint

    render partial: "shared_users"
  end

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