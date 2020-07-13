class AddTargetsToRunningJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :running_jobs, :target_type, :string
    add_column :running_jobs, :target_id, :bigint
  end
end
