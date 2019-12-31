class UserController < ApplicationController

  def dashboard
    @user = current_user
    @uploadedfiles = @user.uploadedfiles
    @sharedfiles = @user.sharedfiles
  end

end