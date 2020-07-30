class User < ApplicationRecord
  has_many :uploadedfiles
  has_many :sharedfiles
  has_many :running_jobs
  include Amistad::FriendModel

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  validates_presence_of     :fname
  validates_presence_of     :lname

  def fullName
    "#{self[:fname]} #{self[:lname]}"
  end

  def delete_user_data
    #check if there are running jobs for this user
    jobs = RunningJob.where("(user_id = ?) OR (target_type = ? AND target_id = ?) OR (second_target_type = ? AND second_target_id = ?)", self.id, "User", self.id, "User", self.id)
    if jobs.length > 0
      pp "THERE ARE RUNNING JOBS FOR THE ACCOUNT----------------------------------"
      return false
    end

    #delete all user data

    #delete notifications
    Notification.where("user_id = ? OR actor_id = ?", self.id, self.id).destroy_all

    #delete my uploaded and shared files
    self.uploadedfiles.each do |uploadedfile|
      ApplicationController.helpers.deleteUploadedFile(uploadedfile)
    end

    # delete files shared with me
    sharedFiles = Sharedfile.where('user_id = ?', self.id)
    sharedFiles.each do |sharedFile|
      sharedFile.audio_file.purge
      sharedFile.destroy
    end

    #delete friends
    friendships = self.friends | self.pending_invited | self.pending_invited
    friendships.each do |friend|
      self.remove_friendship friend
    end

    #delete user
    self.delete

    true
  end
end
