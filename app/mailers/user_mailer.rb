class UserMailer < ApplicationMailer
  default from: 'wavesig59@gmail.com'

  def file_shared_email(user, sharer, uploadedfile)
    @user = user
    @sharer = sharer
    @uploadedfile = uploadedfile
    mail(to: @user.email, subject: 'A File Has Been Shared With You')
  end
end
