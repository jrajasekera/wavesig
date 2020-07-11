class UserMailer < ApplicationMailer
  default from: 'wavesig59@gmail.com'

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

end
