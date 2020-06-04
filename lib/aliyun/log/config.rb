module Aliyun
  module Log
    class Config < Common::AttrStruct
      @endpoint = 'https://cn-beijing.log.aliyuncs.com'
      @open_timeout = 10
      @read_timeout = 120
      class << self
        attr_accessor :endpoint, :access_key_id, :access_key_secret,
                      :open_timeout, :read_timeout

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
      end

      private

        def normalize_endpoint
          uri = URI.parse(endpoint)
          uri = URI.parse("http://#{endpoint}") unless uri.scheme

          if (uri.scheme != 'http') && (uri.scheme != 'https')
            raise 'Only HTTP and HTTPS endpoint are accepted.'
          end

          @endpoint = uri.to_s
        end
    end
  end
end
