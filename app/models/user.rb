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

end
