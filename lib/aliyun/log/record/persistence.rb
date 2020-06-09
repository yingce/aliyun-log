# frozen_string_literal: true

module Aliyun
  module Log
    module Record
      module Persistence
        extend ActiveSupport::Concern

        module ClassMethods
          def logstore_name
            @logstore_name ||= options[:name] || base_class.name.split('::').last.downcase.pluralize
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
            has_index? ? update_index : create_index
          end

          def auto_load_schema
            return if _schema_load

            create_logstore
            sync_index
            self._schema_load = true
          end

          def has_index?
            Log.record_connection.get_index(project_name, logstore_name)
            true
          rescue ServerError
            false
          end

          def create(data, opts = {})
            auto_load_schema
            if data.is_a?(Array)
              logs = []
              data.each do |log_attr|
                logs << new(log_attr).save_array
              end
              res = Log.record_connection.put_log(project_name, logstore_name, logs, opts)
              res.code == 200
            else
              new(data).save
            end
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
            if options[:field_index] == true
              attributes.reject { |_, value| value[:index] == false }
            else
              attributes.select { |_, value| value[:index] == true }
            end
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
            index_conf = raw_conf.dup
            field_indices.each do |k, v|
              index_conf['keys'][k.to_s] ||= v
            end
            return if index_conf['keys'] == raw_conf['keys']

            Log.record_connection.update_index(
              project_name,
              logstore_name,
              index_conf['keys']
            )
          end
        end

        def save
          self.class.auto_load_schema
          run_callbacks(:create) do
            run_callbacks(:save) do
              if valid?
                res = Log.record_connection.put_log(self.class.project_name, self.class.logstore_name, attributes)
                res.code == 200
              else
                false
              end
            end
          end
        end

        def save_array
          run_callbacks(:create) do
            run_callbacks(:save) do
              validate! && attributes
            end
          end
        end
      end
    end
  end
end