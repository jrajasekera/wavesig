class HomeController < ApplicationController
    skip_before_action :authenticate_user!

    def info
        if user_signed_in?
            redirect_to user_dashboard_path(current_user.id)
        end
    end
end