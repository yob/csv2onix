# coding: utf-8
ActionController::Routing::Routes.draw do |map|

  map.resources :csv_files, :member => {:formmap => :get, :ready => :get}

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  map.root :controller => "csv_files"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
