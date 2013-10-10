require 'blacklight_facet_browse/traject_macro'

# We don't actually test with live traject, we just test that the traject macro
# does what we expect, in an essentially mocked traject environment based on our
# understanding of how traject works. Better than nothing!
describe BlacklightFacetBrowse::TrajectMacro do 
  before do 
    @mocked = Object.new 
    @mocked.extend BlacklightFacetBrowse::TrajectMacro
    
    @keygen = BlacklightFacetBrowse::KeyGeneratorV1.new(:en)
  end

  it "adds nothing to accumulator for nil original value" do
    my_lambda = @mocked.browse_normalized_facet("original_field", @keygen)
    mocked_context = OpenStruct.new(:output_hash => {})

    accumulator = []

    my_lambda.call(nil, accumulator, mocked_context)

    assert_empty accumulator
  end

  it "transforms original field into accumulator" do
    my_lambda = @mocked.browse_normalized_facet("original_field", @keygen)

    mocked_context = OpenStruct.new
    original_values = ["one original value", "two original value"]
    mocked_context.output_hash = {
      "original_field" => original_values
    }
    accumulator = []

    # shouldn't use the first arg for marc record, so we'll pass in nil
    my_lambda.call(nil, accumulator, mocked_context)

    # for each value in original, the accumulator has a properly transformed value. 
    assert_equal 2, accumulator.length
    0.upto(original_values.length-1) do |i|
      assert_equal BlacklightFacetBrowse::NormalForm.normal_form(original_values[i], @keygen), accumulator[i]
    end
  end

end