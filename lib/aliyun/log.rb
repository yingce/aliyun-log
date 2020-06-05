# frozen_string_literal: true

require_relative 'log/common'
require_relative 'log/client'
require_relative 'log/config'
require_relative 'log/logstore'
require_relative 'log/project'
require_relative 'log/protobuf'
require_relative 'log/protocol'
require_relative 'log/request'
require_relative 'log/server_error'

module Aliyun
  module Log
    def self.configure
      block_given? ? yield(Config) : Config
    end
  end
end
