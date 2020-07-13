class CreateRunningJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :running_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_id, null: false
      t.string :job_type, null: false
      t.timestamps
    end

    add_index :running_jobs, %i[user_id job_type]
  end
end
