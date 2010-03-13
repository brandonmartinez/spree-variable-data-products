class CreateLineItemVariableFields < ActiveRecord::Migration
  def self.up
    create_table :line_item_variable_fields do |t|
      t.integer :product_variable_field_id, :line_item_id
      t.text :value
      t.timestamps
    end
  end

  def self.down
    drop_table :line_item_variable_fields
  end
end
