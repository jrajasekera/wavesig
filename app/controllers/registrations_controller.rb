class RegistrationsController < Devise::RegistrationsController
  def destroy
    if resource.delete_user_data
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      set_flash_message :notice, :destroyed if is_navigational_format?
      respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
    else
      flash[:alert] = "There are active share or analyze jobs running for your account. Please try deleting your account later."
      redirect_to edit_user_registration_path
    end
  end
end
