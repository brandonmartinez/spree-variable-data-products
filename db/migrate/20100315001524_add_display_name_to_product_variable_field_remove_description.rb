class AddDisplayNameToProductVariableFieldRemoveDescription < ActiveRecord::Migration
  def self.up
    change_table :product_variable_fields do |t|
      t.string :display_name
      t.remove :description
    end
  end

  def self.down
    change_table :product_variable_fields do |t|
      t.remove :display_name
      t.text :description
    end
  end
end