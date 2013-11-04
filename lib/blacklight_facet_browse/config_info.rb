module BlacklightFacetBrowse
  # Class for extracting and querying information
  # from the blacklight_config, relevant to facet browse. 
  #
  # It's initialized with the actual blacklight_config,
  # and then figures out how to get stuff from it.  
  class ConfigInfo
    attr_accessor :blacklight_config, :facet_field

    # Ugh, have to pass in top config AND field_specific config, prob
    # works like this:
    # BrowseConfig.new(blacklight_config, "facet_field_name")
    def initialize(bconfig, ffield)
      self.blacklight_config  = bconfig
      self.facet_field = ffield


      raise ArgumentError.new("Missing second argument facet name in ConfigInfo.new") if ffield.blank?
    end

    def general_config
      blacklight_config["facet_browse"] || {}
    end

    def facet_field_config
      blacklight_config.facet_fields[facet_field] || {}
    end

    def browse_field
      facet_field_config["browse_field"]
    end

    # We started out trying to make this configurable, but
    # there were other callers that needed it without knowing
    # the particular field. So now it's a hard-coded global,
    # but this method is a convenience. 
    def query_param_name
      BlacklightFacetBrowse::QUERY_PARAM
    end

    # If we have a browse field, we consider browse
    # configured for this field, at present. 
    def browse_configured?      
      ! browse_field.nil?
    end

    def browsable_facet_template
      _lookup("browseable_facet_template", "browsable_facet")
    end

    # Extracts key generator from either field-specific
    # or general config. Or WILL RAISE if none is supplied!
    # No defaults for key generator, you need to specify,
    # this is intentional. 
    def key_generator
      keygen = facet_field_config[:browse_key_generator] || general_config[:browse_key_generator]

      unless keygen
        raise ArgumentError.new("Facet browse configured for '#{facet_field}', but no `:browse_key_generator` specified in config!")
      end

      return keygen
    end


    def _lookup(key, default)
      facet_field_config[key] || general_config[key] || default
    end
    
  end
end