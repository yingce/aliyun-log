# frozen_string_literal: true

require 'json'

module Aliyun
  module Log
    class Protocol
      include Common::Logging
      def initialize(config)
        @http = Request.new(config)
      end

      def list_projects(size = nil, offset = nil)
        query = {
          offset: offset,
          size: size
        }.compact
        data = @http.get(nil, query)
        data = JSON.parse(data)
        data['projects'] = data['projects'].map do |attrs|
          Project.from_json(attrs, self)
        end
        data
      end

      def projects(size = nil, offset = nil)
        list_projects(size, offset)['projects']
      end

      def get_project(project_name)
        query = { projectName: project_name }
        attrs = @http.get({ project: project_name }, query)
        attrs = JSON.parse(attrs)
        Project.from_json(attrs, self)
      end

      def create_project(project_name, desc)
        body = {
          projectName: project_name,
          description: desc
        }
        @http.post({ project: project_name }, body.to_json)
      end

      def update_project(project_name, desc)
        body = {
          projectName: project_name,
          description: desc
        }
        @http.put({ project: project_name }, body.to_json)
      end

      def delete_project(project_name)
        body = { projectName: project_name }
        @http.delete({ project: project_name }, body.to_json)
      end

      def list_logstores(project_name, size = nil, offset = nil)
        query = {
          offset: offset,
          size: size
        }.compact
        data = @http.get({ project: project_name, logstore: '' }, query)
        JSON.parse(data)
      end

      def create_logstore(project_name, logstore_name, opt = {})
        body = {
          logstore_name: logstore_name,
          ttl: opt[:ttl] || 365,
          shardCount: opt[:shard_count] || 2,
          autoSplit: opt[:auto_split].nil? ? false : opt[:auto_split],
          maxSplitShard: opt[:max_split_shard],
          enable_tracking: opt[:enable_tracking].nil? ? false : opt[:enable_tracking]
        }.compact
        @http.post({ project: project_name, logstore: '' }, body.to_json)
      end

      def update_logstore(project_name, logstore_name, opt = {})
        body = {
          logstore_name: logstore_name,
          ttl: opt[:ttl] || 365,
          shardCount: opt[:shard_count] || 2,
          autoSplit: opt[:auto_split].nil? ? false : opt[:auto_split],
          maxSplitShard: opt[:max_split_shard],
          enable_tracking: opt[:enable_tracking].nil? ? false : opt[:enable_tracking]
        }.compact
        @http.put({ project: project_name, logstore: logstore_name }, body.to_json)
      end

      def delete_logstore(project_name, logstore_name)
        body = { logstore_name: logstore_name }
        @http.delete({ project: project_name, logstore: logstore_name }, body.to_json)
      end

      def get_logstore(project_name, logstore_name)
        query = { logstore_name: logstore_name }
        attrs = @http.get({ project: project_name, logstore: logstore_name }, query)
        attrs = JSON.parse(attrs)
        attrs['projectName'] = project_name
        Logstore.from_json(attrs, self)
      end

      def put_logs(project_name, logstore_name, content)
        @http.post({ project: project_name, logstore: logstore_name, is_pb: true }, content)
      end

      def put_log(project_name, logstore_name, log_attr)
        contents = log_attr.compact.map { |k, v| { key: k, value: v } }
        log_pb = Protobuf::Log.new(time: Time.now.to_i, contents: contents)
        lg_pb = Protobuf::LogGroup.new(logs: [log_pb])
        @http.post({ project: project_name, logstore: logstore_name, is_pb: true }, lg_pb)
      end

      DEFAULT_LOG_TIME_SHIFT = 900

      def get_logs(project_name, logstore_name, opt = {})
        from = opt[:from] || (Time.now - DEFAULT_LOG_TIME_SHIFT).to_i
        to = opt[:to] || Time.now.to_i
        query = {
          type: 'log',
          from: from,
          to: to,
          line: opt[:line],
          offset: opt[:offset],
          reverse: opt[:reverse],
          query: opt[:query],
          topic: opt[:topic]
        }.compact
        @http.get({ project: project_name, logstore: logstore_name }, query)
      end

      def get_histograms(project_name, logstore_name, opt = {})
        from = opt[:from] || (Time.now - DEFAULT_LOG_TIME_SHIFT).to_i
        to = opt[:to] || Time.now.to_i
        query = {
          type: 'histogram',
          from: from,
          to: to,
          query: opt[:query],
          topic: opt[:topic]
        }.compact
        @http.get({ project: project_name, logstore: logstore_name }, query)
      end

      def list_topics(project_name, logstore_name, opt = {})
        query = {
          type: 'topic',
          line: opt[:line] || 100
        }
        @http.get({ project: project_name, logstore: logstore_name }, query)
      end

      def get_index(project_name, logstore_name)
        query = { logstore_name: logstore_name }
        @http.get({ project: project_name, logstore: logstore_name, action: 'index' }, query)
      end

      INDEX_DEFAULT_TOKEN = ", '\";=()[]{}?@&<>/:\n\t\r".split('')

      def create_index_line(project_name, logstore_name, token = nil)
        body = {
          line: {
            token: token || INDEX_DEFAULT_TOKEN
          }
        }
        @http.post({ project: project_name, logstore: logstore_name, action: 'index' }, body.to_json)
      end

      def create_index(project_name, logstore_name, fields)
        body = {
          line: {
            token: INDEX_DEFAULT_TOKEN
          },
          keys: {}
        }
        fields.each do |k, v|
          body[:keys][k] = v
          v[:token] = INDEX_DEFAULT_TOKEN if %w[text json].include?(v[:type]) && v[:token].blank?
        end
        @http.post({ project: project_name, logstore: logstore_name, action: 'index' }, body.to_json)
      end

      def update_index(project_name, logstore_name, fields)
        body = {
          line: {
            token: INDEX_DEFAULT_TOKEN
          },
          keys: {}
        }
        fields.each do |k, v|
          body[:keys][k] = v
          v[:token] = INDEX_DEFAULT_TOKEN if v[:type] == 'text' && v[:token].blank?
        end
        @http.put({ project: project_name, logstore: logstore_name, action: 'index' }, body.to_json)
      end

      def delete_index(project_name, logstore_name)
        body = { logstore_name: logstore_name }
        @http.delete({ project: project_name, logstore: logstore_name, action: 'index' }, body.to_json)
      end
    end
  end
end
