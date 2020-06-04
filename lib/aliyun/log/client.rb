module Aliyun
  module Log
    class Client
      def initialize(config = {})
        @config = Config.new(config)
        @protocol = Protocol.new(@config)
      end

      def list_projects(size = nil, offset = nil)
        @protocol.list_projects(size, offset)
      end

      def get_project(name)
        @protocol.get_project(name)
      end

      def create_project(name, desc)
        @protocol.create_project(name, desc)
      end

      def update_project(name, desc)
        @protocol.update_project(name, desc)
      end

      def delete_project(name)
        @protocol.delete_project(name)
      end
    end
  end
end
