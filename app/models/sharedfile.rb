class Sharedfile < ApplicationRecord
  has_one_attached :audio_file
  belongs_to :user
  belongs_to :uploadedfile

  after_commit :create_notifications, on: :create

  private

  def create_notifications
    Notification.create do |notification|
      notification.notify_type = 'received_new_share'
      notification.actor = self.uploadedfile.user
      notification.user = self.user
      notification.target = self
    end
  end
end
