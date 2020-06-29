module Aliyun
	module Log
		class LogTail < Common::AttrStruct
			attrs :name, :log_type, :log_path, :file_pattern, :localstore, :time_format,
						:log_begin_regex, :regex, :key, :topic_format,
						:filterKey, :filter_regex, :file_encoding
      def initialize(opts, protocol)
        super(opts)
        @protocol = protocol
      end
		end
	end
end
