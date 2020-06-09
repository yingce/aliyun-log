# frozen_string_literal: true

module Aliyun
  module Log
    module PerThreadRegistry
      def self.extended(object)
        object.instance_variable_set '@per_thread_registry_key', object.name.freeze
      end

      def instance
        Thread.current[@per_thread_registry_key] ||= new
      end

      private

      def method_missing(name, *args, &block)
        singleton_class.delegate name, to: :instance

        send(name, *args, &block)
      end
    end

    class ScopeRegistry
      extend PerThreadRegistry

      def initialize
        @registry = Hash.new { |hash, key| hash[key] = {} }
      end

      def value_for(scope_type, model)
        @registry[scope_type][model.name]
      end

      # Sets the +value+ for a given +scope_type+ and +model+.
      def set_value_for(scope_type, model, value)
        @registry[scope_type][model.name] = value
      end
    end
  end
end
