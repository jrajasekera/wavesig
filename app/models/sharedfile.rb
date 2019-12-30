class Sharedfile < ApplicationRecord
  has_one_attached :audio_file
  belongs_to :user
  belongs_to :uploadedfile
end
