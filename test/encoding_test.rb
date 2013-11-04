# Encoding: UTF-8

require "test_helper.rb"
require 'blacklight_facet_browse/key_generator_v1'

describe "Encoding algorithm V1" do 
  before do    
    @keygen = BlacklightFacetBrowse::KeyGeneratorV1.new
  end

  # first arg turned to a search_key can match second arg as a sort_key
  def matched_by(search, index)
    search_key  = @keygen.search_key(search)
    sort_key    = @keygen.sort_key(index)
    
    assert sort_key.start_with?(search_key), "Index key for '#{index}' should begin with search key for '#{search}'"
  end

  def not_matched_by(search, index)
    search_key  = @keygen.search_key(search)
    sort_key    = @keygen.sort_key(index)
    
    refute sort_key.start_with?(search_key), "Index key for '#{index}' should NOT begin with search key for '#{search}'"
  end

  # test symmetric that one matched by two, and two matched by one
  def equals(one, two)
    matched_by(one, two)
    matched_by(two, one)
  end

  describe "equality" do    
    it "simple ascii" do
      equals("this is just ascii", 'this is just ascii')
    end

    it "doesn't match different strings" do
      not_matched_by("alpha", "beta")
      not_matched_by("beta", "alpha")
    end

    it "normalizes case" do
      equals "ALPHA BETA", "alpha beta"
    end

    it "removes accents" do
      equals("ola, mundo!", "olá, mundo!")
    end

    it "a funny one" do
      equals "internationalizaetion", "Iñtërnâtiônàlizætiøn"
    end

    it "turns 'full width chars' into ascii" do
      equals "p", "\uFF50"
    end

    it "removes more crazy accents" do
      # it's an s with two diacritics, presented two different ways
      equals "s s", "\u0073\u0323\u0307 \u1E69"
    end

    it "turns ohm into omega" do
      equals "\u03A9", "\u2126"
    end

    it "normalizes other weird stuff" do
      # roman numeral 4; ffi ligature; 2 superscript; circle 5; long s
      equals "Henry IV, ffi, 2 5, s", "Henry \u2163, \uFB03, 2 \u2075, \u017F"
    end

    it "doens't ruin CJK" do
      equals "醉馬騮", "醉馬騮"
    end

    it "ignores leading white space" do
      equals " foo", "foo"
    end

    it "equates em-dash and two hyphens" do
      equals "foo--bar", "foo\u2014bar"
    end

    it "equates en-dash and one hyphen" do
      equals "foo-bar", "foo\u2013bar"
    end

    it "ignores spaces around em or double hyphens" do
      equals "foo -- bar", "foo--bar"
      equals "foo \u2014 bar", "foo--bar"
    end
  end

  describe "partial matching" do
    it "can do a begins with match" do
      matched_by("jose", "Joséfina Bové")
    end
  end

  describe "sorting" do
    def in_sort_order(*arr)
      test = arr.dup

      # shuffle it up a bit in a predictable way
      test = test.reverse
      test = test.unshift test.pop

      test = test.sort_by {|v| @keygen.sort_key(v)}

      assert_equal arr, test, "Input array is in sorted order"
    end

    it "sorts ordinary ascii" do
      in_sort_order "alpha", "beta", "gamma", "zed"
    end

    it "sorts case-insensitive" do
      in_sort_order "alpha", "Beta", "dElTa" "EPSILON", "gamma"
    end

    it "sorts diacritics in place as expected" do
      in_sort_order "ab", "ad", "ae" "aéz", "af", "ba"
    end

    it "sorts stroke-o with o" do
      in_sort_order "aaan", "aaaø", "aaaoa"
    end

    it "sorts numbers first" do
      in_sort_order "1", "2", "a", "b"
    end

    it "sorts CJK after latin" do
      in_sort_order "alpha", "beta", "醉馬騮"
    end

    it "ignores leading whitespace" do
      in_sort_order "alpha", " beta", "delta", " epsilon"
    end

    it "ignores leading punctuation" do
      in_sort_order '"alpha"', "beta", '"delta"', "epsilon", "'gamma'"
    end

  end
  
end

