# frozen_string_literal: true

module Aliyun
  module Log
    module Common
      class AttrStruct
        module AttrHelper
          def attrs(*name)
            define_method(:attrs) { name }
            attr_reader(*name)
          end
        end

        extend AttrHelper

        def initialize(opts = {})
          extra_keys = opts.keys - attrs
          raise "Unexpected extra keys: #{extra_keys.join(', ')}" unless extra_keys.empty?

          attrs.each do |attr|
            instance_variable_set("@#{attr}", opts[attr])
          end
        end

        def to_s
          attrs.map do |attr|
            v = instance_variable_get("@#{attr}")
            "#{attr}: #{v}"
          end.join(', ')
        end
      end
    end
  end
end
