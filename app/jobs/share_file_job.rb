class ShareFileJob < ApplicationJob
  queue_as :default

  def perform(shared_user, sharer, uploadedfile)
    watermark = ApplicationController.helpers.generate_watermark
    newShare = Sharedfile.new :user_id => shared_user.id, :uploadedfile_id => uploadedfile.id, :watermark => watermark

    watermarkedFilePath = ApplicationController.helpers.embed_watermark(uploadedfile, watermark)

    newShare.audio_file.attach io: File.open(watermarkedFilePath),
                               filename: uploadedfile.audio_file.filename,
                               content_type: uploadedfile.audio_file.content_type

    File.delete(watermarkedFilePath)

    if newShare.save
      #IT WORKED, create notification for both parties and send email for sharedUser
      UserMailer.file_shared_email(shared_user,sharer,uploadedfile).deliver_later
    else
      #It failed, create notification for sharer
      share_failed_notify(shared_user,sharer,uploadedfile)
    end

    runningJob = RunningJob.find_by(job_id: self.job_id)
    runningJob.destroy
  end

  rescue_from(StandardError) do |exception|
    shared_user = arguments[0]
    sharer = arguments[1]
    uploadedfile = arguments[2]
    pp "I DIDNT SAVE PROPERLY!!!!!!!!!!!!!!!!!!!!!"
    share_failed_notify(shared_user,sharer,uploadedfile)
    runningJob = RunningJob.find_by(job_id: self.job_id)
    runningJob.destroy
  end

  def share_failed_notify(shared_user,sharer,uploadedfile)
    UserMailer.file_share_error_email(shared_user,sharer,uploadedfile).deliver_later
  end

end
