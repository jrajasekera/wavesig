class AddUploadedfileToSharedfiles < ActiveRecord::Migration[5.2]
  def change
    add_reference :sharedfiles, :uploadedfile, foreign_key: true
  end
end
