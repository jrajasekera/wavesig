class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # devise redirect after login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_dashboard_path(resource.id)
  end

  def notifications_count
    @notificationCount = Notification.unread_count(current_user)
    @notificationDisplayCount = @notificationCount.to_s
    if @notificationCount > 9
      @notificationDisplayCount = "9+"
    elsif @notificationCount == 0
      @notificationDisplayCount = ""
    end

    render partial: "notifications_count"
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:fname, :lname, :email, :password)}

      devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:fname, :lname, :email, :password, :current_password)}
    end

end
