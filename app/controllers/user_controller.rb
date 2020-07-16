class UserController < ApplicationController

  def dashboard
    @user = current_user
    @uploadedfiles = @user.uploadedfiles
    @sharedfiles = @user.sharedfiles
    @friends = @user.friends
  end

  def friends
    @user = current_user
    @friends = @user.friends
    @sentRequests = @user.pending_invited
    @receivedRequests = @user.pending_invited_by
  end

  def add_friend
    @add_friend_email_param = params[:friend_email].downcase
    @add_friend_user = User.find_by email: @add_friend_email_param
    @user = current_user

    if @add_friend_user.nil?
      flash[:alert] = @add_friend_email_param + ' is not a current user.'
    else
      invited = @user.invite(@add_friend_user)
      if invited
        Notification.create do |notification|
          notification.notify_type = 'sent_friend_request'
          notification.actor = current_user
          notification.user = @add_friend_user
        end

        flash[:notice] = 'Friend Request Sent to ' + @add_friend_user.email + ' (' + @add_friend_user.fname + ' ' + @add_friend_user.lname + ')!'
      else
        flash[:alert] = 'Failed to Friend Request ' + @add_friend_user.email + '!'
      end
    end

    redirect_to friends_path
  end

  def accept_friend_request
    request_issuer = User.find params[:request_issuer]

    if not request_issuer.nil?
      if current_user.approve(request_issuer)
        Notification.create do |notification|
          notification.notify_type = 'accepted_friend_request'
          notification.actor = current_user
          notification.user = request_issuer
        end

        flash[:notice] = 'Accepted friend request from ' + request_issuer.email
      else
        flash[:alert] = 'Failed to accepted friend request from ' + request_issuer.email
      end
    end

    redirect_to friends_path
  end

  def remove_friend
    friend = User.find params[:friend]

    if not friend.nil?
      if current_user.remove_friendship(friend)
        flash[:notice] = 'Removed  ' + friend.email + '.'
      else
        flash[:alert] = 'Failed to remove ' + friend.email + '.'
      end
    end

    redirect_to friends_path
  end

end