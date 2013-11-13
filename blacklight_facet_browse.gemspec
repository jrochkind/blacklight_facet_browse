$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blacklight_facet_browse/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blacklight_facet_browse"
  s.version     = BlacklightFacetBrowse::VERSION
  s.authors     = ["Jonathan Rochkind"]
  s.email       = ["none"]
  s.homepage    = "http://github.com/jrochkind/blacklight_facet_browse"
  s.summary     = "Features for Blacklight based on a normalized facet prefix search."
  

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "unicode_utils", "~> 1.4"
  # Need twitter_cldr 3.0 for maximum_level on sort keys
  s.add_dependency "twitter_cldr", ">= 3.0.0.beta1" 
  s.add_dependency "unidecoder", ">= 1.1.2"

  s.add_development_dependency "minitest-rails"
  # Do NOT express blacklight as a normal dependency, so
  # it doesn't end up getting loaded when this gem is used just by traject!
  # Hmm, that really applies to rails too. 
  s.add_development_dependency "blacklight", ">= 3.5"
  s.add_development_dependency "rails", "> 3.2"

  s.add_development_dependency "hashie" # helps us mock Blacklight::Configuration

  # We don't use any AR. 
  #s.add_development_dependency "activerecord-jdbcsqlite3-adapter"
end
