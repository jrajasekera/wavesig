class UserController < ApplicationController

  def dashboard
    @user = current_user
    @uploadedfiles = @user.uploadedfiles
    @sharedfiles = @user.sharedfiles
  end

  def find_origin
    @user = current_user
  end

end