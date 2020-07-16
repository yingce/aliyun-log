# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'active_support/core_ext'
require 'active_model'
require 'monitor'

require_relative 'record/exception'
require_relative 'record/field'
require_relative 'record/persistence'
require_relative 'record/scoping'

module Aliyun
  module Log
    module Record
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations

        class_attribute :options, instance_accessor: false, default: {}
        class_attribute :base_class, instance_accessor: false, default: self
        class_attribute :_schema_load, default: false

        Log.included_models << self unless Log.included_models.include? self

        field :__time__, type: :long, cast_type: :integer
        field :__topic__
        field :__source__

        field :created_at, type: :text, cast_type: :datetime if Config.timestamps

        define_model_callbacks :save, :create, :initialize

        before_save :set_created_at

        @lock = Monitor.new
      end

      include Field
      include Persistence
      include Scoping

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

      def new_record?
        @new_record == true
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
