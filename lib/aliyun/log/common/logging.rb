require 'logger'

module Aliyun
  module Log
    module Common
      module Logging
        # DEFAULT_LOG_FILE = './log/aliyun_log.log'.freeze
        DEFAULT_LOG_FILE = STDOUT
        MAX_NUM_LOG = 100
        ROTATE_SIZE = 10 * 1024 * 1024

        def logger
          Logging.logger
        end

        # level = Logger::DEBUG | Logger::INFO | Logger::ERROR | Logger::FATAL
        def self.log_level=(level)
          Logging.logger.level = level
        end

        def self.logger
          unless @logger
            @logger = Logger.new(
              @log_file ||= DEFAULT_LOG_FILE, MAX_NUM_LOG, ROTATE_SIZE
            )
            @logger.level = Logger::DEBUG
          end
          @logger
        end
      end
    end
  end
end
