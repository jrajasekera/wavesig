class ShareFileJob < ApplicationJob
  queue_as :default

  def perform(shared_user, sharer, uploadedfile)
    sleep(5)
  end

  after_perform do |job|
    # sendUser = User.find 1
    UserMailer.file_shared_email(arguments[0],arguments[1],arguments[2]).deliver_later
  end

end
