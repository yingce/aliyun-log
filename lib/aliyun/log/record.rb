# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'active_support/core_ext'
require 'active_model'
require 'forwardable'

require_relative 'record/exception'
require_relative 'record/field'
require_relative 'record/persistence'
require_relative 'record/relation'
require_relative 'record/scope_registry'

module Aliyun
  module Log
    module Record
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations

        class_attribute :options, instance_accessor: false, default: {}
        class_attribute :base_class, instance_accessor: false, default: self
        class_attribute :log_connection, instance_accessor: false
        class_attribute :_schema_load, default: false

        Log.included_models << self unless Log.included_models.include? self

        field :created_at, :text if Config.timestamps

        define_model_callbacks :save, :create, :initialize

        before_save :set_created_at
      end

      include Field
      include Persistence

      include ActiveModel::AttributeMethods

      module ClassMethods
        def logstore(options = {})
          opt = options.dup
          if opt[:timestamps] && !Config.timestamps
            field :created_at, :text
          elsif opt[:timestamps] == false && Config.timestamps
            remove_field :created_at
          end
          self._schema_load = true if opt[:auto_sync] == false
          opt[:field_doc_value] = opt[:field_doc_value] != false
          self.options = opt
        end

        delegate :load, :result, :count, to: :all
        delegate :where, :query, :search, :sql, :from, :to, :page, :line, :limit, :offset, to: :all
        delegate :first, :last, :second, :third, :fourth, :fifth, :find_offset, to: :all

        def current_scope
          ScopeRegistry.value_for(:current_scope, self)
        end

        def current_scope=(scope)
          ScopeRegistry.set_value_for(:current_scope, self, scope)
        end

        def scope(name, body)
          raise ArgumentError, 'The scope body needs to be callable.' unless body.respond_to?(:call)

          singleton_class.send(:define_method, name) do |*args|
            scope = all
            scope = scope.scoping { body.call(*args) }
            scope
          end
        end

        def all
          scope = current_scope
          scope ||= relation.from(0).to(Time.now.to_i)
          scope
        end

        private

        def relation
          Relation.new(self)
        end
      end

      def initialize(attrs = {})
        run_callbacks :initialize do
          @new_record = true
          @attributes ||= {}

          attrs_with_defaults = self.class.attributes.each_with_object({}) do |(attribute, options), res|
            res[attribute] = if attrs.key?(attribute)
                               attrs[attribute]
                             elsif options.key?(:default)
                               evaluate_default_value(options[:default])
                             end
          end

          attrs_virtual = attrs.slice(*(attrs.keys - self.class.attributes.keys))

          attrs_with_defaults.merge(attrs_virtual).each do |key, value|
            if respond_to?("#{key}=")
              send("#{key}=", value)
            else
              raise UnknownAttributeError, "unknown attribute '#{key}' for #{@record.class}."
            end
          end
        end
      end

      def inspect
        inspection = if defined?(@attributes) && @attributes
                       self.class.attributes.keys.collect do |name|
                         "#{name}: #{attribute_for_inspect(name)}" if has_attribute?(name)
                       end.compact.join(', ')
                     else
                       'not initialized'
                     end

        "#<#{self.class} #{inspection}>"
      end

      def attribute_for_inspect(attr_name)
        value = read_attribute(attr_name)

        if value.is_a?(String) && value.length > 50
          "#{value[0, 50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_s(:db)}")
        else
          value.inspect
        end
      end
    end
  end
end
