# frozen_string_literal: true

module Aliyun
  module Log
    class Project < Common::AttrStruct
      attrs :create_time, :description, :last_modify_time,
            :owner, :name, :region, :status

      def initialize(opts, protocol)
        super(opts)
        @protocol = protocol
      end

      def self.from_json(attrs, protocol)
        new({
              create_time: attrs['createTime'],
              description: attrs['description'],
              last_modify_time: attrs['lastModifyTime'],
              owner: attrs['owner'],
              name: attrs['projectName'],
              region: attrs['region'],
              status: attrs['status']
            }, protocol)
      end

      def list_logstores(size = nil, offset = nil)
        @protocol.list_logstores(name, size, offset)
      end

      def get_logstore(logstore_name)
        @protocol.get_logstore(name, logstore_name)
      end

      def create_logstore(logstore_name, opt = {})
        @protocol.create_logstore(name, logstore_name, opt)
      end

      def update_logstore(logstore_name)
        @protocol.update_logstore(name, logstore_name)
      end

      def delete_logstore(logstore_name)
        @protocol.delete_logstore(name, logstore_name)
      end
    end
  end
end
