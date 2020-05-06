class ChangeDefaultName < ActiveRecord::Migration[5.2]
  def change
    change_column_null :users, :fname, true
    change_column_null :users, :fname, true
    change_column_default :users, :fname, from: "FirstName", to: nil
    change_column_default :users, :fname, from: "LastName", to: nil
  end
end
