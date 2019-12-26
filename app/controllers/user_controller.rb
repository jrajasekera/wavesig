class UserController < ApplicationController

  def dashboard
    @user = current_user

  end

  def find_origin
    @user = current_user

  end

end