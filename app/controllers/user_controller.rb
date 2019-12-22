class UserController < ApplicationController

  def dashboard
    user_id = params[:user]
    @user = User.find_by id: user_id

  end

end