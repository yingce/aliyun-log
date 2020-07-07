# frozen_string_literal: true

require_relative 'version'
require_relative 'log/common'
require_relative 'log/client'
require_relative 'log/config'
require_relative 'log/logstore'
require_relative 'log/project'
require_relative 'log/protobuf'
require_relative 'log/protocol'
require_relative 'log/request'
require_relative 'log/server_error'
require_relative 'log/record'

module Aliyun
  module Log
    extend self

    def configure
      block_given? ? yield(Config) : Config
    end
    alias config configure

    def included_models
      @included_models ||= []
    end

    def record_connection
      unless @record_connection
        @record_connection = Protocol.new(Config.new)
      end
      @record_connection
    end

    def init_logstore
      @included_models.each do |model|
        model.create_logstore
        modle.sync_index
      end
    end
  end
end
