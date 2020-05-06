class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :authenticate_user!, :configure_permitted_parameters, if: :devise_controller?

  # devise redirect after login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_dashboard_path(resource.id)
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:fname, :lname, :email, :password)}

      devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:fname, :lname, :email, :password, :current_password)}
    end

end
