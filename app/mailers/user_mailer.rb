class UserMailer < ApplicationMailer
  WAVESIG_EMAIL = 'wavesig59@gmail.com'
  default from: WAVESIG_EMAIL

  def file_shared_email(user, sharer, uploadedfile)
    @user = user
    @sharer = sharer
    @uploadedfile = uploadedfile
    mail(to: @user.email, subject: 'A File Has Been Shared With You')
  end

  def file_share_error_email(user, sharer, uploadedfile)
    @user = user
    @sharer = sharer
    @uploadedfile = uploadedfile
    mail(to: @sharer.email, subject: 'A File You Shared Has Run Into a Processing Error')
  end

  def contact_us_email(name, email, message)
    @name = name
    @email = email
    @message = message
    mail(to: WAVESIG_EMAIL, subject: "Contact Us - Message from #{email}")
  end

end
