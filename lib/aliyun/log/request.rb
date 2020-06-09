# frozen_string_literal: true

require 'rest-client'
require 'base64'
require 'openssl'
require 'digest'
require 'date'
require 'zlib'

module Aliyun
  module Log
    class Request
      include Common::Logging

      def initialize(config)
        @config = config
      end

      def get_resource_path(resources = {})
        resources ||= {}
        res = '/'
        if resources[:logstore]
          res = "#{res}logstores"
          res = "#{res}/#{resources[:logstore]}" unless resources[:logstore].empty?
        end
        res = "#{res}/#{resources[:action]}" if resources[:action]
        res
      end

      def get_request_url(resources = {})
        resources ||= {}
        url = URI.parse(@config.endpoint)
        url.host = "#{resources[:project]}." + url.host if resources[:project]
        url.path = get_resource_path(resources)
        url.to_s
      end

      def get(resources, payload = {})
        do_request('GET', resources, payload)
      end

      def post(resources, payload)
        do_request('POST', resources, payload)
      end

      def put(resources, payload)
        do_request('PUT', resources, payload)
      end

      def delete(resources, payload)
        do_request('DELETE', resources, payload)
      end

      def do_request(verb, resources, payload)
        resource_path = get_resource_path(resources)
        request_options = {
          method: verb,
          url: get_request_url(resources),
          open_timeout: @config.open_timeout,
          read_timeout: @config.read_timeout
        }
        if verb == 'GET'
          headers = compact_headers
          headers['Authorization'] = signature(verb, resource_path, headers, payload)
          request_options[:headers] = headers
          request_options[:url] = URI.escape(canonicalized_resource(request_options[:url], payload))
        else
          headers = compact_headers(payload, resources[:is_pb])
          headers['Authorization'] = signature(verb, resource_path, headers)
          request_options[:headers] = headers
          payload = Zlib::Deflate.deflate(payload.encode) if resources[:is_pb]
          request_options[:payload] = payload
        end
        request = RestClient::Request.new(request_options)
        response = request.execute do |resp|
          if resp.code >= 300
            e = ServerError.new(resp)
            logger.error(e.to_s)
            raise e
          else
            resp.return!
          end
        end

        logger.debug("Received HTTP response, code: #{response.code}, headers: " \
                      "#{response.headers}, body: #{response.body}")

        response
      end

      def compact_headers(body = nil, is_pb = false)
        headers = {
          'x-log-apiversion' => '0.6.0',
          'x-log-signaturemethod' => 'hmac-sha1',
          'x-log-bodyrawsize' => '0',
          'Date' => DateTime.now.httpdate,
          'User-Agent' => "aliyun-log ruby-#{RUBY_VERSION}/#{RUBY_PLATFORM}"
        }
        return headers if body.nil?

        if is_pb
          compressed = Zlib::Deflate.deflate(body.encode)
          headers['Content-Length'] = compressed.bytesize.to_s
          raise 'content length is larger than 3MB' if headers['Content-Length'].to_i > 3_145_728

          headers['Content-MD5'] = Digest::MD5.hexdigest(compressed).upcase
          headers['Content-Type'] = 'application/x-protobuf'
          headers['x-log-compresstype'] = 'deflate'
          headers['x-log-bodyrawsize'] = body.encode.bytesize.to_s
        else
          headers['Content-Type'] = 'application/json'
          headers['Content-MD5'] = Digest::MD5.hexdigest(body.encode).upcase
          headers['x-log-bodyrawsize'] = body.bytesize.to_s
        end
        headers
      end

      def signature(verb, resource, headers, query = {})
        sha1_digest = OpenSSL::HMAC.digest(
          OpenSSL::Digest.new('sha1'),
          @config.access_key_secret,
          string_to_sign(verb, resource, headers, query).chomp
        )
        base64_sign = Base64.strict_encode64(sha1_digest)
        "LOG #{@config.access_key_id}:#{base64_sign}"
      end

      def string_to_sign(verb, resource, headers, query = {})
        <<~DOC
          #{verb}
          #{headers['Content-MD5']}
          #{headers['Content-Type']}
          #{headers['Date']}
          #{canonicalized_headers(headers)}
          #{canonicalized_resource(resource, query)}
        DOC
      end

      def canonicalized_headers(headers)
        h = {}
        headers.each do |k, v|
          h[k.downcase] = v if k =~ /x-log-.*/
        end
        h.keys.sort.map do |e|
          h[e]
          "#{e}:#{h[e].gsub(/^\s+/, '')}"
        end.join("\n")
      end

      def canonicalized_resource(resource = '', query = {})
        return resource if query.empty?

        url = URI.parse(resource)
        sort_str = query.keys.sort.map do |e|
          "#{e}=#{query[e]}"
        end.join('&')
        "#{url}?#{sort_str}"
      end
    end
  end
end
