class HomeController < ApplicationController
    skip_before_action :authenticate_user!

    def info
        if user_signed_in?
            redirect_to user_dashboard_path(current_user.id)
        end
    end

    def contact

    end

    def contactSubmit
        name = ActionController::Base.helpers.sanitize(params['name'])
        email = ActionController::Base.helpers.sanitize(params['email'])
        message = ActionController::Base.helpers.sanitize(params['message'])

        if verify_recaptcha && name.length <= 50 && email.length <= 320 && message.length <= 384000
            UserMailer.contact_us_email(name,email,message).deliver_later

            flash[:notice] = 'Thank you for your message. We will get back to you as soon as possible.'
            redirect_to home_info_path
        else
            flash[:alert] = 'Unable to send message. Please try again later.'
            redirect_to contact_path
        end
    end

    def faq

    end
end