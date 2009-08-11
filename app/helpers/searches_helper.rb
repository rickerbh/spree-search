module SearchesHelper

  # Redefined here to not escape html characters inside the select options, we need to add &nbsp; tags
  # there to change indentation of subitems.
#  def options_for_select(container, selected = nil)
#    container = container.to_a if Hash === container
#
#    options_for_select = container.inject([]) do |options, element|
#      text, value = option_text_and_value(element)
#      selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
#      options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}>#{text.to_s}</option>)
#    end
#
#    options_for_select.join("\n")
#  end

  # Redefined here to not escape html characters inside the select options, we need to add &nbsp; tags
  # there to change indentation of subitems. Changed version to fit option_tags_with_disable plugin.
  def options_for_select(container, selected = nil, disabled = nil)
    container = container.to_a if Hash === container

    options_for_select = container.inject([]) do |options, element|
      text, value = option_text_and_value(element)
      selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
      disabled_attribute = ' disabled="disabled"' if option_value_selected?(value, disabled) && disabled != nil
      options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}#{disabled_attribute}>#{text.to_s}</option>)
    end

    options_for_select.join("\n")
  end

  # Odd. The product search is made inside a helper when the taxon has children. So we change the helper
  # to filter every taxon contents that will be collected to sum up what will be on the preview.
  def taxon_preview(taxon)
    a_search = taxon.products.active.new_search(params[:search])
    a_search.conditions.name_contains = params[:keywords]
    products = a_search.all[0..4]

#    products = taxon.products.active[0..4]
    return products unless products.size < 5
    if Spree::Config[:show_descendents]
      taxon.descendents.each do |taxon|
        another_search = taxon.products.active.new_search(params[:search])
        another_search.conditions.name_contains = params[:keywords]
        products += another_search.all[0..4]

#        products += taxon.products.active[0..4]
        break if products.size >= 5
      end
    end
    products[0..4]
  end
  
    
  # Helper to maintain used search params to not clutter the url.
  def maintain_search_params
    search_params = {}
    search_params.merge!(:taxon => params[:taxon]) if !params[:taxon].nil? && !params[:taxon].empty?
    search_params.merge!(:subtaxons => params[:subtaxons]) if params[:subtaxons] != "0"
    search_params.merge!(:min_price => params[:min_price]) if !params[:min_price].nil? && !params[:min_price].empty?
    search_params.merge!(:max_price => params[:max_price]) if !params[:max_price].nil? && !params[:max_price].empty?
    search_params.merge!(:keywords => params[:keywords]) if !params[:keywords].nil? && !params[:keywords].empty?
    search_params.merge!(:sort => params[:sort]) if !params[:sort].nil? && !params[:sort].empty?
    search_params.merge!(:search => params[:search]) if !params[:search].nil? && !params[:search].empty?

    search_params
  end

end
