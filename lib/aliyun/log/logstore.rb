# frozen_string_literal: true

module Aliyun
  module Log
    class Logstore < Common::AttrStruct
      attrs :name, :project_name, :ttl, :shared_count, :enable_tracking,
            :auto_split, :max_split_shard, :create_time, :last_modify_time

      def initialize(opts, protocol)
        super(opts)
        @protocol = protocol
      end

      def self.from_json(attrs, protocol)
        new({
              name: attrs['logstoreName'],
              project_name: attrs['projectName'],
              ttl: attrs['ttl'],
              shared_count: attrs['shardCount'],
              enable_tracking: attrs['enable_tracking'],
              auto_split: attrs['autoSplit'],
              max_split_shard: attrs['maxSplitShard'],
              create_time: attrs['createTime'],
              last_modify_time: attrs['lastModifyTime']
            }, protocol)
      end

      def put_logs(content)
        @protocol.put_logs(project_name, name, content)
      end

      def put_log(attributes)
        contents = attributes.map { |k, v| { key: k.to_s, value: v.to_s } }
        log = Aliyun::Log::Protobuf::Log.new(
          time: Time.now.to_i,
          contents: contents
        )
        log_group = Aliyun::Log::Protobuf::LogGroup.new(logs: [log])
        put_logs(log_group)
      end

      def get_logs(opts = {})
        @protocol.get_logs(project_name, name, opts)
      end

      def get_histograms(opts = {})
        @protocol.get_histograms(project_name, name, opts)
      end

      def list_topics(opts = {})
        @protocol.list_topics(project_name, name, opts)
      end

      def get_index
        @protocol.get_index(project_name, name)
      end

      def create_index_line(token = nil)
        @protocol.create_index_line(project_name, name, token)
      end

      def create_index(fields)
        @protocol.create_index(project_name, name, fields)
      end

      def update_index(fields)
        @protocol.update_index(project_name, name, fields)
      end

      def delete_index
        @protocol.delete_index(project_name, name)
      end
    end
  end
end
