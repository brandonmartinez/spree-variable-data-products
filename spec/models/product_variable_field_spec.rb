require File.dirname(__FILE__) + '/../spec_helper'

describe ProductVariableField do
  before(:each) do
    @product_variable_field = ProductVariableField.new
  end

  it "should be valid" do
    @product_variable_field.should be_valid
  end
end
