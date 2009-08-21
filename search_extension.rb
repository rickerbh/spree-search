# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class SearchExtension < Spree::Extension
  version "0.99"
  description "Search and sort extension for spree."
  url "http://github.com/romul/spree-search/tree/master"

  def activate
    ProductsController.class_eval do
      private
      def collection
        # Define what is allowed.
        sort_params = {
          "price_asc" => ["master_price", "asc"],
          "price_desc" => ["master_price", "desc"],
          "date_asc" => ["available_on", "asc"],
          "date_desc" => ["available_on", "desc"],
          "name_asc" => ["name", "asc"],
          "name_desc" => ["name", "desc"]
        }
        # Set it to what is allowed or default.
        @sort_by_and_as = sort_params[params[:sort]] || false
        @search_param = "- #{t('ext.search.searching_by', :search_term => params[:keywords])}" if params[:keywords]
        query = params[:keywords]
        if params[:taxon]
          @taxon = Taxon.find(params[:taxon])
          @search = Product.active.scoped(:conditions =>
                                            ["products.name LIKE ? OR products.description LIKE ?
                                              products.id in (select product_id from products_taxons where taxon_id in (" +
                                              @taxon.descendents.inject( @taxon.id.to_s) { |clause, t| clause += ', ' + t.id.to_s} + "))",
                                              "%#{query}%", "%#{query}%"
                                            ]).search(params[:search])
        else
          @search = Product.active.scoped(:conditions =>
                                            ["products.name LIKE ? OR products.description LIKE ?",
                                              "%#{query}%", "%#{query}%"
                                            ]).search(params[:search])
        end
        @search = @search.send "#{@sort_by_and_as[1]}end_by_#{@sort_by_and_as[0]}" if @sort_by_and_as
        @products_count = @search.count
        @products ||= @search.paginate(:include  => [:images, {:variants => :images}],
                                       :per_page => params[:per_page] || Spree::Config[:products_per_page],
                                       :page     => params[:page])
      end
    end
  end

  def self.require_gems(config)
    config.gem 'activerecord-tableless', :lib => 'tableless'
  end
end

