class AddNameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :fname, :string, limit: 50, null: false, default: "FirstName"
    add_column :users, :lname, :string, limit: 50, null: false, default: "LastName"
  end
end
