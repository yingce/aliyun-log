# frozen_string_literal: true

module Aliyun
  module Log
    module Record
      module Field
        extend ActiveSupport::Concern

        # Types allowed in indexes:
        PERMITTED_KEY_TYPES = %i[
          text
          long
          double
          json
        ].freeze

        DEFAULT_INDEX_TOKEN = ", '\";=()[]{}?@&<>/:\n\t\r".split('')

        included do
          class_attribute :attributes, instance_accessor: false, default: {}
        end

        module ClassMethods
          def field(name, type = :text, options = {})
            unless PERMITTED_KEY_TYPES.include?(type)
              raise ArgumentError, "Field #{name} type(#{type}) error, key type only support text/long/double/json"
            end

            named = name.to_s
            self.attributes = attributes.merge(name => { type: type }.merge(options))

            warn_about_method_overriding(name, name)
            warn_about_method_overriding("#{named}=", name)
            warn_about_method_overriding("#{named}?", name)

            define_attribute_method(name) # Dirty API

            generated_methods.module_eval do
              define_method(named) { read_attribute(named) }
              define_method("#{named}?") do
                value = read_attribute(named)
                case value
                when true        then true
                when false, nil  then false
                else
                  !value.nil?
                end
              end
              define_method("#{named}=") { |value| write_attribute(named, value) }
            end
          end

          def remove_field(field)
            field = field.to_sym
            attributes.delete(field) || raise('No such field')

            undefine_attribute_methods
            define_attribute_methods attributes.keys

            generated_methods.module_eval do
              remove_method field
              remove_method :"#{field}="
              remove_method :"#{field}?"
              remove_method :"#{field}_before_type_cast"
            end
          end

          private

          def generated_methods
            @generated_methods ||= begin
              Module.new.tap do |mod|
                include(mod)
              end
            end
          end

          def warn_about_method_overriding(method_name, field_name)
            if instance_methods.include?(method_name.to_sym)
              Common::Logging.logger.warn("Method #{method_name} generated for the field #{field_name} overrides already existing method")
            end
          end
        end

        def attribute_names
          @attributes.keys
        end

        def has_attribute?(attr_name)
          @attributes.key?(attr_name.to_sym)
        end

        def evaluate_default_value(val)
          if val.respond_to?(:call)
            val.call
          elsif val.duplicable?
            val.dup
          else
            val
          end
        end

        attr_accessor :attributes

        def write_attribute(name, value)
          attributes[name.to_sym] = value
        end

        alias []= write_attribute

        def read_attribute(name)
          attributes[name.to_sym]
        end
        alias [] read_attribute

        def set_created_at
          self.created_at ||= DateTime.now.in_time_zone(Time.zone).to_s if timestamps_enabled?
        end

        def timestamps_enabled?
          self.class.options[:timestamps] || (self.class.options[:timestamps].nil? && Config.timestamps)
        end
      end
    end
  end
end
