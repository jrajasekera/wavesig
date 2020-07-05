class Uploadedfile < ApplicationRecord
  belongs_to :user
  has_one_attached :audio_file
  has_many :sharedfiles

  validates :fileName,:audio_file, presence: true
end
