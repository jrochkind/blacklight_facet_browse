require 'blacklight_facet_browse/config_info'
require 'active_support'

module BlacklightFacetBrowse
  # include into a Blacklight CatalogController to provide BlacklightFacetBrowse
  # functionality -- important to include it AFTER the Blacklight mixins, so it
  # can override them. 
  module ControllerMixin

    # OVERRIDING the original method of this name from Blacklight::SolrHelper. 
    # This method creates the query params for solr to fetch facet values
    # for a facet list. 
    #
    # Here we are over-riding to supply our facet.prefix parameters
    # for facet begins-with browsing, properly formulated with calculated
    # search key -- only if so configured for a given facet!
    # 
    def solr_facet_params(facet_field, user_params=params || {}, extra_controller_params={})
      # start out with default
      solr_params = super

      # Now add Solr facet.prefix only if this facet field is
      # configured for such, and we can do something useful --
      # we have a browse query, or want to sort in a locale
      # appropriate way.       
      conf_ext     = ConfigInfo.new(blacklight_config, facet_field)
      browse_query = user_params[ conf_ext.query_param_name ]

      if conf_ext.browse_configured?
        # switch the facet.field to our configured browse field companion
        solr_params[:"facet.field"] = conf_ext.browse_field

        # Copy over field-specific sort and limit, if present
        if limit = solr_params[:"f.#{facet_field}.facet.limit"]
          solr_params[:"f.#{conf_ext.browse_field}.facet.limit"] = limit
        end
        if sort = solr_params[:"f.#{facet_field}.facet.sort"]
          solr_params[:"f.#{conf_ext.browse_field}.facet.sort"] = sort
        end

        # Add facet.prefix if we have a browse query
        if browse_query
          search_key = conf_ext.key_generator.search_key(browse_query)
          solr_params["facet.prefix"] = search_key
        end
      end

      return solr_params
    end
  end
end