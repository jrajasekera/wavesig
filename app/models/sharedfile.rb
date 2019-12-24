class Sharedfile < ApplicationRecord
  belongs_to :user
  belongs_to :uploadedfile
end
