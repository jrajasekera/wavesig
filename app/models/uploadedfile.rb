class Uploadedfile < ApplicationRecord
  belongs_to :user
  has_one_attached :audio_file
  has_many :sharedfiles
  has_many :find_origin_results

  # validates :fileName, presence: true
  validate :audio_file_incorrect_format
  validate :filename_is_incorrect_format

  MAX_UPLOAD_FILE_SIZE = 100.megabytes

  def filename_is_incorrect_format
    if fileName.blank?
      errors.add(:audio_file, "Filename can't be blank.")
    end
  end

  def audio_file_incorrect_format
    if audio_file.attachment.nil?
      errors.add(:audio_file, "Upload file is required.")
    else
      if audio_file.content_type != 'audio/x-wav'
        errors.add(:audio_file, "File has to be in wav format.")
      end
      if audio_file.byte_size > MAX_UPLOAD_FILE_SIZE
        errors.add(:audio_file, "File has to be less than #{MAX_UPLOAD_FILE_SIZE/1.megabytes} MB.")
      end
    end
  end
end
