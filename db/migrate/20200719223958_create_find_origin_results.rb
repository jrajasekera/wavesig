class CreateFindOriginResults < ActiveRecord::Migration[5.2]
  def change
    create_table :find_origin_results do |t|
      t.belongs_to :uploadedfile, null: false
      t.bigint :origin_user_id
      t.timestamps
    end
  end
end
