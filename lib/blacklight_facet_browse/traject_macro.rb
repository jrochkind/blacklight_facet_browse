require 'blacklight_facet_browse/normal_form'

module BlacklightFacetBrowse
  module TrajectMacro

    # Eg
    #
    #     require 'blacklight_facet_browse/traject_macro'
    #     extend BlacklightFacetBrowse::TrajectMacro
    #
    #     to_field "subject", extract_marc("600:650:610")
    #     to_field "subject_browse", browse_normalized_facet("subject", BlacklightFacetBrowse::KeyGeneratorV1.new)
    #
    # The second key generator arg is REQUIRED, to make compatibility
    # issues absolutely transparent if key generation algorithm is changed. 
    def browse_normalized_facet(original_field, key_generator)
      lambda do |record, accumulator, context|
        original_values = context.output_hash[original_field] || []

        original_values.each do |original_value|
          accumulator << BlacklightFacetBrowse::NormalForm.normal_form(original_value, key_generator)
        end        
      end
    end
  end
end