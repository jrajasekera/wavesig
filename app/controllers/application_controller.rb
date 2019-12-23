class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :authenticate_user!

  # devise redirect after login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_dashboard_path(resource.id)
  end



end
