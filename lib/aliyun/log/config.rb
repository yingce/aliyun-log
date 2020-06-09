# frozen_string_literal: true

require 'logger'
module Aliyun
  module Log
    class Config < Common::AttrStruct
      @endpoint = 'https://cn-beijing.log.aliyuncs.com'
      @open_timeout = 10
      @read_timeout = 120
      @log_level = Logger::DEBUG
      @timestamps = true
      class << self
        attr_accessor :endpoint, :access_key_id, :access_key_secret,
                      :open_timeout, :read_timeout, :log_file, :log_level,
                      :timestamps, :project

        def configure
          yield self
        end
      end

      attrs :endpoint, :access_key_id, :access_key_secret,
            :open_timeout, :read_timeout

      def initialize(opts = {})
        super(opts)
        @open_timeout ||= self.class.open_timeout
        @read_timeout ||= self.class.read_timeout
        @access_key_id ||= self.class.access_key_id
        @access_key_secret ||= self.class.access_key_secret
        @endpoint ||= self.class.endpoint
        normalize_endpoint
        raise 'Missing AccessKeyID or AccessKeySecret' if @access_key_id.nil? || @access_key_secret.nil?
      end

      private

      def normalize_endpoint
        uri = URI.parse(endpoint)
        uri = URI.parse("http://#{endpoint}") unless uri.scheme

        raise 'Only HTTP and HTTPS endpoint are accepted.' if (uri.scheme != 'http') && (uri.scheme != 'https')

        @endpoint = uri.to_s
      end
    end
  end
end
