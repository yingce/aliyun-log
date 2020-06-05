# frozen_string_literal: true

require 'logger'

module Aliyun
  module Log
    module Common
      module Logging
        MAX_NUM_LOG = 100
        ROTATE_SIZE = 10 * 1024 * 1024

        def logger
          Logging.logger
        end

        # level = Logger::DEBUG | Logger::INFO | Logger::ERROR | Logger::FATAL
        def self.log_level=(level)
          @logger_level = level
          Logging.logger.level = level
        end

        def self.logger=(logger)
          @logger = logger
        end

        def self.log_file=(log_file)
          @logger = Logger.new(
            log_file, MAX_NUM_LOG, ROTATE_SIZE
          )
          @logger.level = Logging.logger_level
        end

        def self.logger_level
          @logger_level ||= Config.log_level
          @logger_level
        end

        def self.logger
          unless @logger
            @logger = Logger.new(
              @log_file ||= Config.log_file, MAX_NUM_LOG, ROTATE_SIZE
            )
            @logger.level = Logging.logger_level
          end
          @logger
        end
      end
    end
  end
end
