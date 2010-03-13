class LineItemVariableField < ActiveRecord::Base
  belongs_to :line_item
  belongs_to :product_variable_field
end
