class AddSecondaryTargetsToRunningJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :running_jobs, :second_target_type, :string
    add_column :running_jobs, :second_target_id, :bigint
  end
end
