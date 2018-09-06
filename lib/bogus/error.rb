# frozen_string_literal: true
require "bogus/error/version"
require 'json'

module Bogus
  module Error
    module_function :bogus_error
    @Lock = Mutex.new
    @HandlerCount = 0

    def bogus_error(filename)
      n, error_kind = 0, 0
      error_class_name = nil
      @Lock.synchronize do
        n = @HandlerCount
        @HandlerCount += 1
        begin
          if (m = /(\w*)_(handler|controller)\.rb$/.match(filename))
            name, kind = m.to_a[1..-1]
            json_file = __FILE__.sub(/_generator.rb$/, "_#{kind}.json")
            Rails.logger.debug(StandardError.new("   looking for '#{name}' in #{json_file} (called from #{filename})"))
            File.open(json_file) do |file|
              data = JSON.parse file.read
              if (error_class_name = data.delete(name))
                File.open(json_file, 'w') do |file|
                  file.write(JSON.pretty_generate(data) + "\n")
                end
              end
            end
          else
            Rails.logger.debug(StandardError.new("   ERROR: bogus_error cannot handle call from #{filename}"))
          end
        rescue Errno::ENOENT
        end
      end
      Rails.logger.debug(StandardError.new("   I've been instructed to raise #{error_class_name || 'nothing'}"))
      return unless error_class_name
      error_class = error_class_name.classify.constantize
      Rails.logger.debug(StandardError.new("   raising #{error_class} on request ##{n} -- BOGUS"))
      raise error_class, "   my BOGUS #{error_class} on request ##{n}"
    end
  end
end
