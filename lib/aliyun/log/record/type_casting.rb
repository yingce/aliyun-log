# frozen_string_literal: true

require 'json'

module Aliyun
  module Log
    module Record
      module TypeCasting
        TYPE_MAPPING = {
          text: :string,
          long: :integer,
          double: :float,
          json: :json
        }.freeze

        def self.cast_field(value, options)
          options ||= {}
          type = options[:cast_type]
          type ||= TYPE_MAPPING[options[:type]]

          return value if options.nil?
          return nil if value.nil?

          caster = Registry.lookup(type)
          raise ArgumentError, "Unknown type #{options[:type]}" if caster.nil?

          caster.new(options).cast(value)
        end

        def self.dump_field(value, options)
          options ||= {}
          type = options[:cast_type]
          type ||= TYPE_MAPPING[options[:type]]

          return value if options.nil?
          return nil if value.nil?

          dumper = Registry.lookup(type)
          raise ArgumentError, "Unknown type #{options[:type]}" if dumper.nil?

          dumper.new(options).dump(value)
        end

        class Value
          def initialize(options)
            @options = options
          end

          def cast(value)
            value
          end

          def dump(value)
            value
          end
        end

        class StringType < Value; end

        class DateType < Value
          def cast(value)
            return nil unless value.respond_to?(:to_date)

            value.to_date
          end

          def dump(value)
            if value.respond_to?(:to_date)
              value.to_date.to_s
            else
              value.to_s
            end
          end
        end

        class DateTimeType < Value
          def cast(value)
            return nil unless value.respond_to?(:to_datetime)

            dt = begin
                   ::DateTime.parse(value)
                 rescue StandardError
                   nil
                 end
            if dt
              seconds = string_utc_offset(value) || 0
              offset = seconds_to_offset(seconds)
              ::DateTime.new(dt.year, dt.mon, dt.mday, dt.hour, dt.min, dt.sec, offset)
            else
              value.to_datetime
            end
          end

          def dump(value)
            if value.respond_to?(:to_datetime)
              value.to_datetime.iso8601
            else
              value.to_s
            end
          end

          private

          def string_utc_offset(string)
            Date._parse(string)[:offset]
          end

          def seconds_to_offset(seconds)
            ActiveSupport::TimeZone.seconds_to_utc_offset(seconds)
          end
        end

        class IntegerType < Value
          def cast(value)
            if value == true
              1
            elsif value == false
              0
            elsif value.is_a?(String) && value.blank?
              nil
            elsif value.is_a?(Float) && !value.finite?
              nil
            elsif !value.respond_to?(:to_i)
              nil
            else
              value.to_i
            end
          end
        end

        class BigDecimalType < Value
          def cast(value)
            if value == true
              1
            elsif value == false
              0
            elsif value.is_a?(Symbol)
              value.to_s.to_d
            elsif value.is_a?(String) && value.blank?
              nil
            elsif value.is_a?(Float) && !value.finite?
              nil
            elsif !value.respond_to?(:to_d)
              nil
            else
              value.to_d
            end
          end
        end

        class FloatType < Value
          def cast(value)
            if value == true
              1
            elsif value == false
              0
            elsif value.is_a?(Symbol)
              value.to_s.to_f
            elsif value.is_a?(String) && value.blank?
              nil
            elsif value.is_a?(Float) && !value.finite?
              nil
            elsif !value.respond_to?(:to_f)
              nil
            else
              value.to_f
            end
          end
        end

        class JsonType < Value
          def cast(value)
            return value unless value.is_a?(String)

            begin
              ActiveSupport::JSON.decode(value)
            rescue StandardError
              nil
            end
          end

          def dump(value)
            ActiveSupport::JSON.encode(value) unless value.nil?
          end
        end

        module Registry
          module_function

          @registrations = {}

          def register(name, klass = nil)
            @registrations[name.to_sym] = klass
          end

          def lookup(name)
            name ||= :string
            @registrations[name.to_sym]
          end

          register(:string, StringType)
          register(:date, DateType)
          register(:datetime, DateTimeType)
          register(:bigdecimal, BigDecimalType)
          register(:integer, IntegerType)
          register(:float, FloatType)
          register(:json, JsonType)
        end
      end
    end
  end
end
