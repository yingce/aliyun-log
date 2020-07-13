# frozen_string_literal: true

require 'active_support/core_ext'

module Aliyun
  module Log
  	module Utils
	  	module_function
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

	    def get_request_url(endpoint, resources = {})
	      resources ||= {}
	      url = URI.parse(endpoint)
	      url.host = "#{resources[:project]}." + url.host if resources[:project]
	      url.path = get_resource_path(resources)
	      url.to_s
	    end
	  end
  end
end
