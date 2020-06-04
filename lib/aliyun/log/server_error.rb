require 'json'

module Aliyun
  module Log
    class ServerError < StandardError
      attr_reader :http_code, :error_code, :raw_message, :request_id

      def initialize(response)
        @http_code = response.code
        body = JSON.parse(response.body)
        @error_code = body['errorCode']
        @raw_message = body['errorMessage']
        if @error_code == 'IndexInfoInvalid'
          human_info = ' please see the rules: ' \
                       'https://help.aliyun.com/document_detail/74953.html'
          @raw_message += human_info
        end
        @request_id = response.headers['x-log-requestid']
      end

      def message
        @raw_message || "UnknownError[#{http_code}]."
      end

      def to_s
        msg = @raw_message || "UnknownError[#{http_code}]."
        "error_code: #{@error_code} message: #{msg} RequestId: #{request_id}"
      end
    end
  end
end
