require 'blacklight_facet_browse/config_info'
require 'blacklight_facet_browse/normal_form'
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
  
    # OVERRIDE #facet to use our custom views that can handle
    # browse normalized facets. If the facet isn't configured
    # for browse, we just call super though. 
    def facet
      @browse_config = BlacklightFacetBrowse::ConfigInfo.new(blacklight_config, params[:id])

      if ! @browse_config.browse_configured?
        # first do no harm, do nothing if the facet ain't configured
        # for browse. 
        super
      else
        # Mostly copied and modified from current BL 4.4, although will work
        # with older BL, in some cases adding features. Use
        # our custom get_browse_facet_pagination

        # If no other sort is specified, and we have no prefix query,
        # insist on defaulting to 'index', anything else is confusing.         
        if params["catalog_facet.sort"].blank? && params[ @browse_config.query_param_name ].present?
          params["catalog_facet.sort"] = "index"
        end


        @pagination = get_browse_facet_pagination(params[:id], params)

        respond_to do |format|        
          format.html do 
            # we're going to use a custom view, possibly user specified,
            # but the default is "browsable_facet"
            render @browse_config.browsable_facet_template
          end

          # Draw the partial for the "more" facet modal window,
          # without layout. 
          format.js { render @browse_config.browsable_facet_template, :layout => false }

          # Json format copied from BL 4.4, there was no json response in
          # BL 3.5, we need one, sure let's use that one to try and be compat.  
          #format.json { render json: {response: {facets: @pagination }}}
        end
      end
    end
  
    # This is a new action method added by this plugin. 
    # It returns JUST the individual partial for a single sidebar facet--
    # used for ajax 'starts with' search limiting.
    def facet_limit_content
      browse_config = BlacklightFacetBrowse::ConfigInfo.new(blacklight_config, params[:id])
      browse_field  = browse_config.browse_field

      # insist on sorting alphabetically for our sidebar prefix limit
      # if we have a prefix query -- too confusing otherwise. 
      force_solr_params = {}
      if params[ browse_config.query_param_name ].present?
         force_solr_params[:"f.#{browse_field}.facet.sort"] = "index"
       end
      pagination    = get_browse_facet_pagination(params[:id], params, force_solr_params)

      partial       = browse_config.facet_field_config[:partial] || "browsable_facet_limit"

      render :partial=>partial, :layout => false, 
        :locals => {:paginator => pagination, :solr_field => params[:id], :facet_field => browse_config.facet_field_config}
    end

    protected

    # A customized version of Blacklight's SolrHelper#get_facet_pagination 
    # that we use for getting facet values from Solr and wrapping them in a Pagination object
    # -- BUT WITH respect for facet.prefix.  There are a few other things it needs to do too. 
    #
    # Originally we tried to use the original BL get_facet_pagination and over-ride
    # other parts, but ran into barriers, including different behavior in different
    # BL versions in ways that effected us, as well as BL's continued confusion
    # between app params and extra_solr_params. 
    #
    # In this method, 'app_params' are the params from the user-facing
    # application itself, from the app's own URL.  extra_solr_params
    # are parameters for the request we're going to make to solr, that
    # we want to forcefully merge in before we make the solr request. We
    # do our best to keep em separate. 
    def get_browse_facet_pagination(facet_field, app_params=params, extra_solr_params = {})
      solr_params = solr_facet_params(facet_field, app_params.dup, {})
      solr_params = solr_params.deep_merge(extra_solr_params)
      
      # Make the solr call -- whether what we need is stored in 'qt' or 'request_handler'
      # may depend on BL version, gah. 
      request_handler = blacklight_config.qt || blacklight_config.solr_request_handler
      response =find(request_handler, solr_params)

      # This is a BL 3.5 version of finding limit, master doesn't look
      # at :facet_list_limit?
      limit =       
        if respond_to?(:facet_list_limit)
          facet_list_limit.to_s.to_i
        elsif solr_params[:"f.#{facet_field}.facet.limit"]
          solr_params[:"f.#{facet_field}.facet.limit"] - 1
        else
          nil
        end
      
      # Actually create the paginator!
      # NOTE: The sniffing of the proper sort from the solr response is not
      # currently tested for, tricky to figure out how to test, since the
      # default setup we test against doesn't use this feature. 
      return     Blacklight::Solr::FacetPaginator.new(response.facets.first.items, 
        :offset => solr_params[:"f.#{facet_field}.facet.offset"] || solr_params['facet.offset'], 
        :limit => limit,
        :sort => response["responseHeader"]["params"]["f.#{facet_field}.facet.sort"] || response["responseHeader"]["params"]["facet.sort"]
      )
    end




  end
end