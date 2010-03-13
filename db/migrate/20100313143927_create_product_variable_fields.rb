class CreateProductVariableFields < ActiveRecord::Migration
  def self.up
    create_table :product_variable_fields do |t|
      t.integer :product_id
      t.string :name
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :product_variable_fields
  end
end
