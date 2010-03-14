# Put your extension routes here.

# map.namespace :admin do |admin|
#   admin.resources :whatever
# end  

map.namespace :admin do |admin|
  admin.resources :products do |product|
    product.resources :product_variable_fields
  end
end

map.resources :orders do |order|
  order.resources :line_items, :member => {:render_proof => :get}
end