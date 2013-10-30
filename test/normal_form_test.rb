# Encoding: UTF-8

require 'test_helper'
require 'blacklight_facet_browse/normal_form'

describe "normal form" do
  let(:keygen) {  BlacklightFacetBrowse::KeyGeneratorV1.new }

  it "begins with sort key" do
    str = "Iñtërnâtiônàlizætiøn"
    assert BlacklightFacetBrowse::NormalForm.normal_form(str, keygen).start_with? keygen.sort_key(str)
  end

  it "round trips a bunch of crazy things" do
    [ "alpha", "ALPHA", "Iñtërnâtiônàlizætiøn",
      "Henry \u2163, \uFB03, 2 \u2075, \u017F",  
      "醉馬騮"].each do |str|
      normal_form = BlacklightFacetBrowse::NormalForm.normal_form(str, keygen)
      extracted   = BlacklightFacetBrowse::NormalForm.extract_original(normal_form)

      assert_equal str, extracted, "Can round trip"
    end
  end

  describe "extract_original" do

    # If no seperator, just return original; to have a better failure
    # mode, AND importantly so we can use this method in places
    # it might be dealing with original facet content! This
    # is actually part of API, needs to stay this way. 
    it "just uses input as-is if no SEPERATOR" do
      original = "This is just plain text, not normalized form."

      normal_form = BlacklightFacetBrowse::NormalForm.extract_original(original)

      assert_equal original, normal_form, "Output is same as input"
    end
  end

end