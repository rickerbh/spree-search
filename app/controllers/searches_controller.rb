class SearchesController < Spree::BaseController
  layout 'application'
  helper :application, :taxons, :products

  def test
  end
  
  def filter_price
    @search = Search.new
    @search.taxon_id = params[:taxon_id] if params[:taxon_id].to_i > 0
    @search.keywords = params[:keywords]
    @search.subtaxons = true 
    render :layout => false if request.xhr?  
  end
  
  
  # Create a search object to receive parameters of the form to validate.
  def new
    @search = Search.new
  end
  
  # Validates the search object and redirect to show action renaming the parameters to not clash with searchlogic.
  def create
    @search = Search.new(params[:search])
    if @search.valid?

      # Build the custom parameters hash and don't clutter the url with empty params.
      temp = {}
      temp.merge!(:taxon => params["search"]["taxon_id"]) if !params["search"]["taxon_id"].empty?
      temp.merge!(:subtaxons => params["search"]["subtaxons"]) if params["search"]["subtaxons"] == "1"
      temp.merge!(:min_price => params["search"]["min_price"]) if !params["search"]["min_price"].empty?
      temp.merge!(:max_price => params["search"]["max_price"]) if !params["search"]["max_price"].empty?
      temp.merge!(:keywords => params["search"]["keywords"]) if !params["search"]["keywords"].empty?
      temp.merge!(:sort => params["sort_type"]) if !params["sort_type"].nil?
      redirect_to temp.merge(:action => 'show')
    else
      render :action => 'new'
    end
  end
  
  def show
    # Define what is allowed.
    sort_params = {
      "price_asc" => ["variants.price", "asc"],
      "price_desc" => ["variants.price", "desc"],
      "date_asc" => ["available_on", "asc"],
      "date_desc" => ["available_on", "desc"],
      "name_asc" => ["name", "asc"],
      "name_desc" => ["name", "desc"]
    }

    query = params[:keywords]
    # Set it to what is allowed or default.
    @sort_by_and_as = sort_params[params[:sort]] || false 
    
    scope = { :conditions => ["products.name LIKE ? OR products.description LIKE ?", "%#{query}%", "%#{query}%"] }
    scope.merge!({ :order => "#{@sort_by_and_as[0]} #{@sort_by_and_as[1]}" }) if @sort_by_and_as
    
    @search = Product.active.scoped(scope).search(params[:search])

    if params[:taxon]
      if params[:subtaxons]
        an_array = []

        a_taxon = Taxon.first(:conditions => ["taxons.id IN (?)", params[:taxon]]) #{:id_is => params[:taxon]})
        add_subtaxons(an_array, a_taxon) if a_taxon

        @search = @search.taxons_id_equals(an_array)
      else
        @search = @search.taxons_id_equals(params[:taxon])
      end
    end
    
    @search = @search.master_price_greater_than_or_equal_to(params[:min_price]) if params[:min_price]
    @search = @search.master_price_less_than_or_equal_to(params[:max_price]) if params[:max_price]

    @products_count = @search.count
    @products ||= @search.paginate(:include  => [:images, {:variants => :images}],
                                   :per_page => Spree::Config[:products_per_page],
                                   :page     => params[:page])   
                                                                                                                                     
end


  private
  
  def add_subtaxons(taxon_array, taxon)
    taxon_array << taxon.id
    taxon.children.each do |subtaxon|
      add_subtaxons(taxon_array, subtaxon)
    end
  end

end
