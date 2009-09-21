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
          "price_asc" => ["variants_price", "asc"],
          "price_desc" => ["variants_price", "desc"],
          "date_asc" => ["available_on", "asc"],
          "date_desc" => ["available_on", "desc"],
          "name_asc" => ["name", "asc"],
          "name_desc" => ["name", "desc"]
        }
        # Set it to what is allowed or default.
        @sort_by_and_as = sort_params[params[:sort]] || sort_params['date_desc']
               
        @search = Product.active
        @search = @search.send "#{@sort_by_and_as[1]}end_by_#{@sort_by_and_as[0]}" if @sort_by_and_as
        
        if params[:taxon]
          @taxon = Taxon.find(params[:taxon])         
          @search = @search.taxons_id_equals_any(@taxon.descendents.inject([@taxon.id]) { |clause, t| clause << t.id } )                          
        end
        
        unless params[:keywords].blank?
          query = params[:keywords].to_s.split
          @search = @search.name_or_description_like_any(query)
        end  
        
        @search = @search.search(params[:search])
        
        @products_count = @search.count
        @products ||= @search.paginate(:include  => [:images, {:variants => :images}],
                                       :per_page => params[:per_page] || Spree::Config[:products_per_page],
                                       :page     => params[:page])
      end
    end
  end

  def self.require_gems(config)
    config.gem 'activerecord-tableless', :lib => 'tableless'
    config.gem 'searchlogic', :version => '>=2.3.3'
  end
end

