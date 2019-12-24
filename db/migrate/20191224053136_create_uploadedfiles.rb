class CreateUploadedfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :uploadedfiles do |t|
      t.string :fileName, limit: 100
      t.string :description, limit: 280

      t.timestamps
    end
  end
end
