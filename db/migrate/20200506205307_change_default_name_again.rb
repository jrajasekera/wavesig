class ChangeDefaultNameAgain < ActiveRecord::Migration[5.2]
  def change
    change_column_default :users, :lname, from: "LastName", to: nil
  end
end
