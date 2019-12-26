class UserController < ApplicationController

  def dashboard
    @user = current_user

    @uploadedfiles = Uploadedfile.where user_id: @user.id

  end

  def find_origin
    @user = current_user

  end

end