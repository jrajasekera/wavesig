class AddWatermarkToSharedfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :sharedfiles, :watermark, :string
  end
end
