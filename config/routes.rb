# Put your extension routes here.

map.search_test '/search/test', :controller => 'searches', :action => 'test'
map.resources :searches
map.price_filter '/price/filter/:taxon_id', :controller => 'searches', :action => 'filter_price'
