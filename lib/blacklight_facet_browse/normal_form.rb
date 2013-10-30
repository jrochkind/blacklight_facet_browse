module BlacklightFacetBrowse
  # Utilities for putting a string into facet browse normal form, and
  # extracting original out of facet browse normal form
  #
  # normal_form = BlacklightFacetBrowse::NormalForm.normal_form("foo", BlacklightFacetBrowse::KeyGeneratorV1.new)
  # original    = BlacklightFacetBrowse::NormalForm.extract_original( normal_form )
  module NormalForm
    # make all methods class methods
    extend self

    # "\t" is one the lowest byte valued legal char in xml/json, 
    # important for keeping collation proper despite our suffix payload.     
    SEPARATOR = "\t_$SEP$_"

    # Put a source string into facet browse normal form. 
    # The sort_key of the source, followed by a seperator, followed by the original source. 
    def normal_form(source_string, key_generator)
      sort_key = key_generator.sort_key(source_string)
      "#{key_generator.sort_key(source_string)}#{SEPARATOR}#{source_string}"
    end

    # Extract an original source string out of facet browse normal form
    def extract_original(normal_form)
      start = normal_form.index(SEPARATOR)

      # If no seperator, just return original; to have a better failure
      # mode, AND importantly so we can use this method in places
      # it might be dealing with original facet content!
      return normal_form unless start

      range = (start+SEPARATOR.length)..(normal_form.length)
      return normal_form.slice( range  )
    end

  end
end