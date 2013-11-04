require 'twitter_cldr'

module BlacklightFacetBrowse

  # Create sort keys for indexing, and search keys for starts-with
  # facet.prefix searching over those sort keys. 
  #
  # If this logic changed, you'd need to rebuild your index. So
  # this class ends in "V1" with the idea that any future versions
  # will be named differently, and then future verisons of this
  # gem can still support V1 for backwards compat. 
  #
  # Uses Unicode collation; defaults to english locale, but you can
  # choose another locale (results may vary, not currently covered
  # by CI).  You can also send in custom pre-processing mappings (todo)
  #
  #
  # The API methods used by callers are #sort_key and #search_key, 
  # that's the Key Generator API ; other methods are mostly intended
  # for internal use. 
  class KeyGeneratorV1
    def initialize(locale = :en)
      @collator = TwitterCldr::Collation::Collator.new(locale)
    end

    def sort_key(input)
      generate_key(:index, input)
    end

    def search_key(input)
      generate_key(:search, input)
    end

    def generate_key(mode, input)
      # Some pre-processing normalization
      input = pre_process(input)

      # Now turn it into a unicode collation key -- restricted to level 1
      # for a search key. 
      maximum_level = (mode == :search) ? 1 : nil
      # Returns array of 16-bit ints
      unicode_key_arr = @collator.get_sort_key(input, :maximum_level => maximum_level)

      unicode_key = stringify(unicode_key_arr)
      
      return unicode_key
    end

    # Any pre-processing we have to do of input before feeding to
    # unicode collation algorithm. 
    def pre_process(input)
      # I am surprised that unicode collation for locale english
      # pays attention to leading whitespace and punctuation, even
      # at level 1.  But it seems to, so we manually strip it
      # in pre-processing. 
      input = input.gsub(/\A[[:punct:][:space:]]+/u, '')

      # em dash to two hyphens
      input.gsub!(/\u2014/u, '--')
      # en dash to one hyphen
      input.gsub!(/\u2013/u, '-')

      return input
    end

    # Some 
    def pre_process_map

    end

    # Takes a UCA sort key as an array of 16-bit ints,
    # turns it into a single string -- currently an ASCII
    # hex representation, ie "1a20bf" etc
    def stringify(sort_key_arr)
      # We could theoretically turn it into a binary string like this:      
      #return sort_key_arr.pack("n*")
      # But that is going to possibly include NUL bytes, as well
      # as other control chars. 

      # But is generally less fragile to turn into an ascii hex
      # representation instead, eg "197a8fb2". Will take up more space,
      # but is safe for including in XML, JSON, etc., where this thing
      # will end up travelling. 
      sort_key_arr.map { |i| i.to_s(16).rjust(2, "0") }.join('')
    end


  end
end