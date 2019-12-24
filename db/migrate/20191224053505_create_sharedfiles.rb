class CreateSharedfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :sharedfiles do |t|

      t.timestamps
    end
  end
end
