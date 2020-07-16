# frozen_string_literal: true

require 'protobuf'

module Aliyun
  module Log
    module Protobuf
      class Log < ::Protobuf::Message
        required :uint32, :time, 1

        class Content < ::Protobuf::Message
          required :string, :key, 1
          required :string, :value, 2
        end

        repeated Content, :contents, 2
      end

      class LogTag < ::Protobuf::Message
        required :string, :key, 1
        required :string, :value, 2
      end

      class LogGroup < ::Protobuf::Message
        repeated Log, :logs, 1
        optional :string, :reserved, 2
        optional :string, :topic, 3
        optional :string, :source, 4
        repeated LogTag, :log_tags, 6
      end
    end
  end
end
