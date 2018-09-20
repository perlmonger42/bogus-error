# frozen_string_literal: true
#require 'bogus/error/version'
require 'json'

class DummyModel
  include ActiveModel::Model
  attr_accessor :display_name

  def initialize
    errors.add(:foo, 'bad fu')
  end

  def id
    'ITbc75a6238fa74bc66790416d4a2a73da'
  end
end

module Bogus
  module Error
    @Lock = Mutex.new
    @HandlerCount = 0
    FILENAME_REGEX = %r{^(/.*)/app/.*?([^/]*)_(handler|controller)\.rb$}

    # Convert a string like 'ActiveRecord::StatementInvalid' into the
    # corresponding constant ActiveRecord::StatementInvalid.
    # (This code was copied from the `activesupport-inflector` gem.)
    module_function
    def constantize(camel_cased_word) #:nodoc:
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name, false) ?
          constant.const_get(name) :
          constant.const_missing(name)
      end
      constant
    end

    module_function
    def generate(logger, filename)
      n, error_class_name = 0, nil
      return unless (m = FILENAME_REGEX.match(filename))
      root, name, kind = m.to_a[1..-1]
      # filename should look like '/srv/forge/app/handlers/foo_handler.rb'
      # root should look like, e.g., '/srv/forge'
      # name should look like, e.g., 'foo'
      # kind should be either 'handler' or 'controller'
      json_file = "#{root}/config/#{kind}_bogus_errors.json"
      json_data = '<uninitialized>'
      @Lock.synchronize do
        n = @HandlerCount
        @HandlerCount += 1
        begin
          if (m = /(\w*)_(handler|controller)\.rb$/.match(filename))
            logger.debug(StandardError.new("   looking for '#{name}' in #{json_file} (called from #{filename})"))
            json_data = File.read(json_file).chomp
            data = JSON.parse json_data
            if (error_class_name = data.delete(name))
              File.open(json_file, 'w') do |file|
                file.write(JSON.generate(data))
              end
            end
          else
            logger.debug(StandardError.new("   ERROR: bogus_error cannot handle call from #{filename}"))
          end
        rescue Errno::ENOENT => err
          logger.debug(err)
        end
      end

      logger.debug(StandardError.new("   read json #{json_data} from #{json_file}"))
      log_msg = "I have not been instructed to raise anything"
      actual_error_class_name = nil
      if error_class_name == 'NOTHING'
        log_msg = "I've been explicitly instructed to raise NOTHING"
      elsif error_class_name
        log_msg = "I've been instructed to raise #{error_class_name}"
        actual_error_class_name = error_class_name
      end
      file = caller_locations.first.path
      logger.debug(StandardError.new("   #{log_msg} from #{file}"))
      return unless actual_error_class_name
      error_class = constantize(actual_error_class_name)
      logger.debug(StandardError.new("   raising #{error_class} on request ##{n} -- BOGUS"))
      args = actual_error_class_name == 'Medkit::Base' ?  args = ['default_error'] :
        actual_error_class_name == 'Medkit::Model' ? args = [DummyModel.new, {}] :
             []
      logger.debug(StandardError.new("   this is a special #{actual_error_class_name} exception with args #{args.inspect}")) if args.size > 0
      raise error_class.new(*args)
    end
  end
end
###      logger.debug(StandardError.new("   I've been instructed to raise #{error_class_name || 'nothing'} from #{caller_locations.first.path}")) if error_class_name
###      return unless error_class_name
###      error_class = constantize(error_class_name)
###      logger.debug(StandardError.new("   raising #{error_class} on request ##{n} -- BOGUS"))
###      if error_class_name == 'Medkit::Base'
###        logger.debug(StandardError.new("   this is a Medkit::Base exception"))
###	raise Medkit::Base.new(:unknown_error)
###      else
###        raise error_class.new(:unknown_error)
###      end
