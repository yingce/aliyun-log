# frozen_string_literal: true

module Aliyun
  module Log
    module Record
      module Persistence
        RESERVED_FIELDS = %i[
          __time__
          __topic__
          __source__
          __partition_time__
          __extract_others__
        ].freeze

        extend ActiveSupport::Concern

        module ClassMethods
          def logstore_name
            @logstore_name ||= options[:name] ||
                               base_class.name.split('::').last.underscore.pluralize
          end

          def logstore_name=(value)
            if defined?(@logstore_name)
              return if value == @logstore_name
            end

            @logstore_name = value
          end

          def project_name
            unless @project_name
              @project_name = options[:project] || Config.project
              raise ProjectNameError, "project can't be empty" if @project_name.blank?
            end
            @project_name
          end

          def create_logstore(options = {})
            Log.record_connection.get_logstore(project_name, logstore_name)
          rescue ServerError => e
            Log.record_connection.create_logstore(project_name, logstore_name, options)
          end

          def sync_index
            return if field_indices.blank?
            has_index? ? update_index : create_index
          end

          def auto_load_schema
            @lock.synchronize do
              return if _schema_load
              create_logstore
              sync_index
              self._schema_load = true
            end
          end

          def has_index?
            Log.record_connection.get_index(project_name, logstore_name)
            true
          rescue ServerError
            false
          end

          def create(data, force = false)
            auto_load_schema
            if data.is_a?(Array)
              # TODO batch insert
              data.each do |log|
                saved = new(log).save(force)
                return false unless saved
              end
            else
              new(data).save(force)
            end
          end

          def create!(data)
            create(data, true)
          end

          private

          def evaluate_default_value(val)
            if val.respond_to?(:call)
              val.call
            elsif val.duplicable?
              val.dup
            else
              val
            end
          end

          def field_indices
            indices = if options[:field_index] == false
                        attributes.select { |_, value| value[:index] == true }
                      else
                        attributes.reject { |_, value| value[:index] == false }
                      end
            indices.reject { |key, _| RESERVED_FIELDS.include?(key) }
          end

          def create_index
            Log.record_connection.create_index(
              project_name,
              logstore_name,
              field_indices
            )
          end

          def update_index
            conf_res = Log.record_connection.get_index(project_name, logstore_name)
            raw_conf = JSON.parse(conf_res)
            index_conf = raw_conf.deep_dup
            field_index_types.each do |k, v|
              index_conf['keys'] ||= {}
              index_conf['keys'][k.to_s] ||= {}
              index_conf['keys'][k.to_s].merge!(v.as_json)
            end
            return if index_conf['keys'] == raw_conf['keys']

            Log.record_connection.update_index(
              project_name,
              logstore_name,
              index_conf['keys'].with_indifferent_access
            )
          end

          def field_index_types
            field_indices.tap do |tap|
              tap.each do |_, v|
                v[:alias] ||= ''
                v[:caseSensitive] ||= false
                v[:chn] ||= false
                v[:doc_value] = options[:field_doc_value] != false if v[:doc_value].nil?
              end
            end
          end
        end

        def dump_log_tags
          log_tags = {}
          self.class.tag_attributes.map do |key, options|
            log_tags[key] = TypeCasting.dump_field(attributes[key], options)
          end
          log_tags.compact
        end

        def dump_attributes
          attributes.dup.tap do |tap|
            tap.each do |k, v|
              if self.class.attributes[k][:log_tag] || RESERVED_FIELDS.include?(k)
                tap.delete(k)
              else
                tap[k] = TypeCasting.dump_field(v, self.class.attributes[k])
              end
            end
          end
        end

        def save(force = false)
          self.class.auto_load_schema
          run_callbacks(:create) do
            run_callbacks(:save) do
              force && validate!
              return false unless valid?
              saved = put_logs
              @new_record = false if saved
              saved
            end
          end
        end

        def save!
          save(true)
        end

        private

        def put_logs
          log_tags = []
          dump_log_tags.each do |k, v|
            log_tags << Protobuf::LogTag.new(key: k, value: v)
          end
          lg = Protobuf::LogGroup.new(
            logs: [generate_log],
            log_tags: log_tags,
            topic: read_attribute(:__topic__),
            source: read_attribute(:__source__)
          )
          res = Log.record_connection.put_logs(
            self.class.project_name,
            self.class.logstore_name,
            lg
          )
          res.code == 200
        end

        def generate_log
          time = read_attribute(:__time__) || Time.now.to_i
          contents = dump_attributes.map { |k, v| { key: k, value: v.to_s } }
          Protobuf::Log.new(time: time, contents: contents)
        end
      end
    end
  end
end
