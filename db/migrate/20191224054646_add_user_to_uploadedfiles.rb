class AddUserToUploadedfiles < ActiveRecord::Migration[5.2]
  def change
    add_reference :uploadedfiles, :user, foreign_key: true
  end
end
