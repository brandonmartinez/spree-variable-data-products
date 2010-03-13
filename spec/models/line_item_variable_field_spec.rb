require File.dirname(__FILE__) + '/../spec_helper'

describe LineItemVariableField do
  before(:each) do
    @line_item_variable_field = LineItemVariableField.new
  end

  it "should be valid" do
    @line_item_variable_field.should be_valid
  end
end
