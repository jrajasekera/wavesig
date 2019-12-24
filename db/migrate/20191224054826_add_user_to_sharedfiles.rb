class AddUserToSharedfiles < ActiveRecord::Migration[5.2]
  def change
    add_reference :sharedfiles, :user, foreign_key: true
  end
end
