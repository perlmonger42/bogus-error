require "test_helper"

class Bogus::ErrorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bogus::Error::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
