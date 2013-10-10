module BlacklightFacetBrowse
  module Util
    # make all methods class methods
    extend self

    # "\t" is one the lowest byte valued legal char in xml/json, 
    # important for keeping collation proper despite our suffix payload.     
    NORMAL_FORM_SEPERATOR = "\t_$SEP$_"

    # The sort_key of the source, followed by a seperator, followed by the original source. 
    def index_normal_form(source_string, key_generator)
      sort_key = key_generator.sort_key(source_string)
      "#{key_generator.sort_key(source_string)}#{NORMAL_FORM_SEPERATOR}#{source_string}"
    end

    def extract_original(normal_form)
      
    end

  end
end