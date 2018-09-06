# frozen_string_literal: true
require 'bogus/error/version'
require 'json'

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
      @Lock.synchronize do
        n = @HandlerCount
        @HandlerCount += 1
        begin
          if (m = /(\w*)_(handler|controller)\.rb$/.match(filename))
            logger.debug(StandardError.new("   looking for '#{name}' in #{json_file} (called from #{filename})"))
            data = {}
            File.open(json_file) { |file| data = JSON.parse file.read }
            if (error_class_name = data.delete(name))
              File.open(json_file, 'w') do |file|
                file.write(JSON.pretty_generate(data) + "\n")
              end
            end
          else
            logger.debug(StandardError.new("   ERROR: bogus_error cannot handle call from #{filename}"))
          end
        rescue Errno::ENOENT
        end
      end
      logger.debug(StandardError.new("   I've been instructed to raise #{error_class_name || 'nothing'}"))
      return unless error_class_name
      error_class = constantize(error_class_name)
      logger.debug(StandardError.new("   raising #{error_class} on request ##{n} -- BOGUS"))
      raise error_class, "   my BOGUS #{error_class} on request ##{n}"
    end
  end
end
