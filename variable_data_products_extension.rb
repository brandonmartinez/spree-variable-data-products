# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

require 'lib/PdfGenerator'

class VariableDataProductsExtension < Spree::Extension
  version "1.0"
  description "Adds the ability to create web-to-print and variable data items in Spree by using iText. WORK IN PROGRESS"
  url "http://github.com/brandonmartinez/spree-variable-data-products"

  # Please use variable_data_products/config/routes.rb instead for extension routes.

  def self.require_gems(config)
    config.gem "rjb"
    config.gem "radius"
  end
  
  def activate

    # Add your extension tab to the admin.
    # Requires that you have defined an admin controller:
    # app/controllers/admin/yourextension_controller
    # and that you mapped your admin in config/routes

    #Admin::BaseController.class_eval do
    #  before_filter :add_yourextension_tab
    #
    #  def add_yourextension_tab
    #    # add_extension_admin_tab takes an array containing the same arguments expected
    #    # by the tab helper method:
    #    #   [ :extension_name, { :label => "Your Extension", :route => "/some/non/standard/route" } ]
    #    add_extension_admin_tab [ :yourextension ]
    #  end
    #end
    
    Product.class_eval do
      has_many :product_variable_fields, :dependent => :destroy, :attributes => true
      
      def has_variable_fields?
        !product_variable_fields.empty?
      end
    end
    
    LineItem.class_eval do
      has_many :line_item_variable_fields, :dependent => :destroy, :attributes => true
      
      def has_variable_fields?
        !line_item_variable_fields.empty?
      end
    end
    
    Variant.class_eval do
      has_many :product_variable_fields, :through => :product
    end
    
    Variant.additional_fields += [ {:name => 'Template', :only => [:product]}  ]
    
    Order.class_eval do
      def add_variant(variant, variable_fields, quantity=1)
        current_item = contains?(variant)
        
        if current_item && current_item.line_item_variable_fields.empty? # only allow updating when it's not a variable order
          current_item.increment_quantity unless quantity > 1
          current_item.quantity = (current_item.quantity + quantity) if quantity > 1
          current_item.save
        else
          current_item = LineItem.new(:quantity => quantity)
          
          # check to see if it's a variable item, and if so, add the fields to the line item
          if variable_fields != nil
            for field in variable_fields
              current_item.line_item_variable_fields << field
            end
          end
          
          current_item.variant = variant
          current_item.price   = variant.price
          self.line_items << current_item
        end

        # populate line_items attributes for additional_fields entries
        # that have populate => [:line_item]
        Variant.additional_fields.select{|f| !f[:populate].nil? && f[:populate].include?(:line_item) }.each do |field| 
          value = ""

          if field[:only].nil? || field[:only].include?(:variant)
            value = variant.send(field[:name].gsub(" ", "_").downcase)
          elsif field[:only].include?(:product)
            value = variant.product.send(field[:name].gsub(" ", "_").downcase)
          end
          current_item.update_attribute(field[:name].gsub(" ", "_").downcase, value)
        end
      end
    end
    
    OrdersController.class_eval do
      create.after do
        variable_fields = []
        
        if params[:variable_fields] != nil
          for vfield in params[:variable_fields]
            li = LineItemVariableField.new();
            li.product_variable_field_id = vfield[0]
            li.value = vfield[1]
          
            variable_fields << li
          end
        else
          variable_fields = nil
        end
        
        params[:products].each do |product_id,variant_id|
          quantity = params[:quantity].to_i if !params[:quantity].is_a?(Array)
          quantity = params[:quantity][variant_id].to_i if params[:quantity].is_a?(Array)
          @order.add_variant(Variant.find(variant_id), variable_fields, quantity) if quantity > 0
        end if params[:products]

        params[:variants].each do |variant_id, quantity|
          quantity = quantity.to_i
          @order.add_variant(Variant.find(variant_id), variable_fields, quantity) if quantity > 0
        end if params[:variants]

        @order.save

        # store order token in the session
        session[:order_token] = @order.token
      end
    end
    
    LineItemsController.class_eval do
      def render_proof
        li = LineItem.find(params[:id])
        fields = {}
        
        # create fields hash that contains variable data to merge
        for field in li.line_item_variable_fields
          fields[field.product_variable_field.name] = field.value
        end
        
        # Setup the output path
        output_path = File.join(RAILS_ROOT, "lib/pdfproofs", ("proof-order-" + params[:order_id] + "-li-" + params[:id] + ".pdf"))
        
        # Create the PdfGenerator and render the proof
        pdf = PdfGenerator.new()
        pdf.render_pdf_proof(li.product.template, fields, output_path)
        
        # Send the file to the browser
        render :file => output_path, :content_type => 'application/pdf'
        
        # Remove proof from file system; don't need them lingering around
        File.delete(output_path) 
      end
    end

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end
  end
end
