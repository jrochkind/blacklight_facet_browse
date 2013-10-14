require 'test_helper'

require 'active_support'

require 'blacklight_facet_browse/controller_mixin'
require 'blacklight_facet_browse/key_generator_v1'



# We do NOT currently integration test in a real Blacklight app,
# or really a real Rails app. This is just mocked unit testing
# in isolation. 
describe BlacklightFacetBrowse::ControllerMixin do
  # We tried to use a real Blacklight::Configuration object, but BL
  # made it too hard, we'll just make a Hashie that simulates it,
  # can be used nested. 
  require 'hashie'
  class Conf < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::IndifferentAccess
  end
  before do 
    # It's not even close to a Rails controller, just the
    # bare minimum to support the ControllerMixin
    mock_controller_class = Class.new do 
      # to make it easy for tests to set it, set it to our
      # internal Conf class for faking a BL configuration. 
      attr_accessor :blacklight_config
      
      # include anon module pretending to be superclass,
      # so our mixin can override and call super
      include( Module.new do 
        # a base implementation for the mixin to call super
        def solr_facet_params(facet_field, user_params=params || {}, extra_controller_params={})
          return original_output
        end

        def params
          {}
        end

        def original_output
          @original_output ||= {:"facet.field" => "original", "other" => "other"}
        end
      end)

      include BlacklightFacetBrowse::ControllerMixin
    end


    @controller = mock_controller_class.new
    @keygen = BlacklightFacetBrowse::KeyGeneratorV1.new
    @controller.blacklight_config = Conf.new(
      :facet_browse => {
        :browse_key_generator => @keygen
      },
      :facet_fields => {
        :subject_facet => {
          :browse_field => "subject_browse_facet"
        }
      }
    )    
  end

  describe "solr_facet_params" do
    it "raises with no key generator set" do
      @controller.blacklight_config[:facet_browse][:browse_key_generator] = nil

      assert_raises(ArgumentError) do
        @controller.solr_facet_params("subject_facet", "facet.begins_with" => "foo")
      end
    end

    describe "for a non-configured field" do
      it "doesn't change superclass params" do
        output = @controller.solr_facet_params("other_facet", "facet.begins_with" => "foo")
        assert_equal @controller.original_output, output
      end
    end

    describe "for a configured filed with no begins_with" do
      it "changes facet.field but nothing else" do
        output = @controller.solr_facet_params("subject_facet", {})
        assert_equal "subject_browse_facet", output[:"facet.field"], "changes facet.field"
        assert_equal @controller.original_output.except(:"facet.field"), output.except(:"facet.field"), "does not change other keys"
      end
    end

    describe "for a configured field with begins_with" do
      it "changes facet.field and adds facet.prefix" do
        output = @controller.solr_facet_params("subject_facet", "facet.begins_with" => "foo")

        assert_equal  "subject_browse_facet", output[:"facet.field"], "changes facet.field"
        assert output["facet.prefix"].present?, "adds facet.prefix"
        assert_equal @keygen.search_key("foo"), output["facet.prefix"], "creates proper facet.prefix with keygen"
      end

      it "copies field-specific limit and sort" do
        @controller.original_output.merge!(:"f.subject_facet.facet.sort" => "index", :"f.subject_facet.facet.limit" => 25)
        
        output = @controller.solr_facet_params("subject_facet", "facet.begins_with" => "foo")

        assert_equal 25,       output[:"f.subject_browse_facet.facet.limit"]
        assert_equal "index",  output[:"f.subject_browse_facet.facet.sort"]
      end
    end



  end


end