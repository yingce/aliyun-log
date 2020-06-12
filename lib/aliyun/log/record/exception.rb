module Aliyun
  module Log
    module Record
      class ArgumentError < StandardError; end
      class UnknownAttributeError < StandardError; end
      class ProjectNameError < StandardError; end
      class ParseStatementInvalid < StandardError; end
    end
  end
end
