class AddTemplateProperty < ActiveRecord::Migration
  def self.up
    change_table :products do |t|
      t.text :template
    end
  end

  def self.down
    change_table :products do |t|
      t.remove :template
    end
  end
end