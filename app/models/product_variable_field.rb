class ProductVariableField < ActiveRecord::Base
  belongs_to :product
  has_many :line_item_variable_fields, :dependent => :destroy
  has_many :line_items, :through => :line_item_variable_fields
end
