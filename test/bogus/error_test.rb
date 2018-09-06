require "test_helper"

class Bogus::ErrorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bogus::Error::VERSION
  end

  def test_expected_log_output
    logger = Logger.new
    Bogus::Error.generate(logger, '/srv/acme/app/handlers/baz_handler.rb')
    assert_equal logger.message[0],
      %q{   looking for 'baz' in /srv/acme/config/handler_bogus_errors.json} +
      %q{ (called from /srv/acme/app/handlers/baz_handler.rb)}
    assert_equal logger.message[1], %q{   I've been instructed to raise nothing}
  end

  def test_no_app_no_output
    logger = Logger.new
    Bogus::Error.generate(logger, '/srv/acme/non-app/handlers/baz_handler.rb')
    assert_equal logger.message.size, 0
  end

  def test_raise
    logger = Logger.new
    # this file is .../test/bogus/error_test.rb; set test_root to '.../test'
    test_root = File.dirname(File.dirname(__FILE__))
    fake_ruby_filename = "#{test_root}/fixtures/app/sample_controller.rb"
    real_json_filename = "#{test_root}/fixtures/config/controller_bogus_errors.json"
    File.open(real_json_filename, 'w') { |f| f.write '{"sample":"ArgumentError"}' }
    assert_raises ArgumentError do
      Bogus::Error.generate(logger, fake_ruby_filename)
    end
    json = Regexp.escape(real_json_filename)
    ruby = Regexp.escape(fake_ruby_filename)
    assert_match %r{looking for 'sample' in #{json}.*called from #{ruby}}, logger.message[0]
    assert_match %r{I've been instructed to raise ArgumentError}, logger.message[1]
    assert_match %r{raising ArgumentError on request #\d+}, logger.message[2]
    assert_equal 3, logger.message.size
  end
end

class Logger
  attr_reader :message

  def initialize
    @message = []
  end

  def debug(error)
    @message << error.to_s
  end
end
