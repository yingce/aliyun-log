# frozen_string_literal: true

module Aliyun
  module Log
    module Record
      class Relation
        def initialize(klass, opts = {})
          @klass = klass
          @opts = opts
          @klass.auto_load_schema
          @opts[:search] ||= '*'
        end

        def from(from)
          ts = from.is_a?(Integer) ? from : from.to_time.to_i
          @opts[:from] = ts
          self
        end

        def to(to)
          ts = to.is_a?(Integer) ? to : to.to_time.to_i
          @opts[:to] = ts
          self
        end

        def line(val)
          @opts[:line] = val.to_i
          self
        end
        alias limit line

        def offset(val)
          @opts[:offset] = val.to_i
          self
        end

        def page(val)
          @opts[:page] = val - 1 if val >= 1
          self
        end

        def where(opts)
          @opts.merge!(opts)
          self
        end

        def search(str)
          @opts[:search] = str
          self
        end

        def sql(str)
          @opts[:sql] = str
          self
        end

        def query(opts = {})
          @opts[:query] = opts
          self
        end

        def count
          query = @opts.dup
          if query[:query].blank?
            where_cond = query[:sql].split(/where /i)[1] if query[:sql].present?
            query[:query] = "#{query[:search]}|SELECT COUNT(*) as count"
            query[:query] = "#{query[:query]} WHERE #{where_cond}" if where_cond.present?
          end
          res = Log.record_connection.get_logs(@klass.project_name, @klass.logstore_name, query)
          res = JSON.parse(res.body)
          res[0]['count'].to_i
        end

        def result
          query = @opts.dup
          if query[:page]
            query[:line] ||= 100
            query[:offset] = query[:page] * query[:line]
          end
          query[:query] = query[:search]
          query[:query] = "#{query[:query]}|#{query[:sql]}" if query[:sql].present?
          res = Log.record_connection.get_logs(@klass.project_name, @klass.logstore_name, query)
          JSON.parse(res)
        end

        def load
          result.map do |json_attr|
            attrs = {}
            @klass.attributes.keys.each do |k, _|
              attrs[k] = json_attr[k.to_s]
            end
            @klass.new(attrs)
          end
        end
      end
    end
  end
end
