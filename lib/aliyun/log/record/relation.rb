# frozen_string_literal: true

module Aliyun
  module Log
    module Record
      class Relation
        def initialize(klass, opts = {})
          @klass = klass
          @opts = opts
          @klass.auto_load_schema
        end

        def inspect
          "#<#{self.class}>"
        end

        def first(line = 1)
          find_offset(0, line, false)
        end

        def second
          find_offset(1)
        end

        def third
          find_offset(2)
        end

        def fourth
          find_offset(3)
        end

        def fifth
          find_offset(4)
        end

        def last(line = 1)
          data = find_offset(0, line, true)
          line > 1 ? data.reverse : data
        end

        def find_offset(nth, line = 1, reverse = false)
          # @opts[:select] = '*'
          @opts[:line] = line
          @opts[:offset] = nth
          if @opts[:order].present? && reverse
            conds = []
            @opts[:order].split(',').each do |field|
              field.gsub!(/\s+desc|asc.*/i, '')
              conds << "#{field.strip} DESC"
            end
            @opts[:order] = conds.join(', ')
          end
          @opts[:order] ||= reverse ? '__time__ DESC' : '__time__ ASC'
          if @opts[:select].blank?
            line <= 1 ? load[0] : load
          else
            line <= 1 ? result[0] : result
          end
        end

        def scoping
          previous = @klass.current_scope
          @klass.current_scope = self
          yield
        ensure
          @klass.current_scope = previous
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
          singleton_class.send(:define_method, :total_count) do
            @total_count ||= count
          end
          singleton_class.send(:define_method, :total_pages) do
            (total_count.to_f / (@opts[:line] || 100)).ceil
          end
          self
        end

        def api(opts)
          @opts.merge!(opts)
          self
        end

        def search(*statement)
          ql = statement_ql(*statement)
          @opts[:search] = ql if ql.present?
          self
        end

        def sql(*statement)
          unless statement[0].is_a?(String)
            raise ParseStatementInvalid, 'Only support string statement'
          end
          ql = sanitize_array(*statement)
          @opts[:sql] = ql if ql.present?
          self
        end

        def where(*statement)
          if statement[0].is_a?(String)
            ql = sanitize_array(*statement)
            @opts[:where] = ql
          else
            ql = statement_ql(*statement)
            @opts[:search] = ql
          end
          self
        end

        def select(*fields)
          @opts[:select] = fields.join(', ')
          self
        end

        def group(*fields)
          @opts[:group] = fields.join(', ')
          self
        end

        def order(*fields)
          if fields[0].is_a?(Hash)
            @opts[:order] = fields[0].map do |k, v|
              unless %w[asc desc].include?(v.to_s)
                raise ArgumentError, "Direction \"#{v}\" is invalid. Valid directions are: [:asc, :desc, :ASC, :DESC]" 
              end
              "#{k} #{v}"
            end.join(', ')
          else
            @opts[:order] = fields.join(', ')
          end
          self
        end

        def query(opts = {})
          @opts[:query] = opts
          self
        end

        def count
          # @opts[:select] = 'COUNT(*) as count'
          _sql = to_sql
          sql = "SELECT COUNT(*) as count"
          sql += " FROM(#{_sql})" if _sql.present?
          query = @opts.dup
          query[:query] = "#{query[:search] || '*'}|#{sql}"
          res = execute(query)
          res.dig(0, 'count').to_i
        end

        def sum(field)
          @opts[:select] = "SUM(#{field}) as sum"
          query = @opts.dup
          query[:query] = "#{query[:search] || '*'}|#{to_sql}"
          res = execute(query)
          res.dig(0, 'sum').to_f
        end

        def result
          query = @opts.dup
          query[:query] = query[:search] || '*'
          sql = to_sql
          if sql.present?
            query[:query] += "|#{sql}"
            @opts[:line] = nil
            @opts[:offset] = nil
            @opts[:page] = nil
          end
          execute(query)
        end

        def load
          result.map do |json_attr|
            record = @klass.new
            json_attr.each do |key, value|
              record.send("#{key}=", value) if record.respond_to?("#{key}=")
            end
            record
          end
        end

        def to_sql
          opts = @opts.dup
          sql_query = []
          sql_query << "WHERE #{opts[:where]}" if opts[:where].present?
          sql_query << "GROUP BY #{opts[:group]}" if opts[:group].present?
          sql_query << "ORDER BY #{opts[:order]}" if opts[:order].present?
          if sql_query.present? || opts[:select].present?
            sql_query.insert(0, "SELECT #{opts[:select] || '*'}")
            sql_query.insert(1, 'FROM log')
            if opts[:line] || opts[:page] || opts[:offset]
              parse_page
              sql_query << "LIMIT #{@opts[:offset]},#{@opts[:line]}"
            end
          end
          "#{opts[:query]}#{sql_query.join(' ')}"
        end

        private

        def execute(query)
          puts query.slice(:from, :to, :search, :query).to_json
          res = Log.record_connection.get_logs(@klass.project_name, @klass.logstore_name, query)
          JSON.parse(res)
        end

        def parse_page
          @opts[:line] ||= 100
          @opts[:page] ||= 0
          @opts[:offset] = @opts[:page] * @opts[:line]
        end

        def statement_ql(*statement)
          if statement.size == 1
            sanitize_hash(statement.first)
          elsif statement.size > 1
            sanitize_array(*statement)
          end
        end

        def sanitize_hash(search_content)
          return search_content unless search_content.is_a?(Hash)

          search_content.select { |_, v| v.present? }.map do |key, value|
            options = @klass.attributes[:"#{key}"]
            unless options
              raise UnknownAttributeError, "unknown field '#{key}' for #{@klass.name}."
            end

            raise_if_hash_quote(value)

            cast_type = options[:cast_type]
            if value.is_a?(Array)
              values = value.uniq.map { |v| _quote(cast_type, v) }
              str_values = values.map { |v| "#{key}: #{v}" }.join(' OR ')
              values.size > 1 ? "(#{str_values})" : str_values
            elsif value.is_a?(Range)
              "#{key} in [#{value.begin} #{value.end}]"
            else
              "#{key}: #{_quote(cast_type, value)}"
            end
          end.join(' AND ')
        end

        def sanitize_array(*ary)
          statement, *values = ary
          if values.first.is_a?(Hash) && /:\w+/.match?(statement)
            replace_named_bind_variables(statement, values.first)
          elsif statement.include?('?')
            replace_bind_variables(statement, values)
          elsif statement.blank? || values.blank?
            statement
          else
            statement % values.collect(&:to_s)
          end
        end

        def replace_named_bind_variables(statement, bind_vars)
          statement.gsub(/(:?):([a-zA-Z]\w*)/) do |match|
            if bind_vars.include?(match = Regexp.last_match(2).to_sym)
              match_value = bind_vars[match]
              raise_if_hash_quote(match_value)
              if match_value.is_a?(Array) || match_value.is_a?(Range)
                values = match_value.map { |v| _quote_type_value(v) }
                values.join(', ')
              else
                _quote_type_value(match_value)
              end
            else
              raise ParseStatementInvalid, "missing value for :#{match} in #{statement}"
            end
          end
        end

        def replace_bind_variables(statement, values)
          expected = statement.count('?')
          provided = values.size
          if expected != provided
            raise ParseStatementInvalid, "wrong number of bind variables (#{provided} " \
                                         "for #{expected}) in: #{statement}"
          end
          bound = values.dup
          statement.gsub(/\?/) do
            value = bound.shift
            raise_if_hash_quote(value)
            if value.is_a?(Array) || value.is_a?(Range)
              values = value.map { |v| _quote_type_value(v) }
              values.join(', ')
            else
              _quote_type_value(value)
            end
          end
        end

        def _quote(type, value)
          v = TypeCasting.cast_field(value, cast_type: type || :string)
          case type
          when :string, nil then "'#{v.to_s}'"
          when :bigdecimal  then v.to_s("F")
          when :integer     then v.to_s.to_i
          when :datetime, :date then "'#{v.iso8601}'"
          else
            value.to_s
          end
        end

        def _quote_type_value(value)
          case value.class.name
          when 'String'                   then "'#{value.to_s}'"
          when 'BigDecimal', 'Float'      then value.to_s("F")
          when 'Date', 'DateTime', 'Time' then "'#{value.iso8601}'"
          else
            value
          end
        end

        def raise_if_hash_quote(value)
          if value.is_a?(Hash) || value.is_a?(ActiveSupport::HashWithIndifferentAccess)
            raise ParseStatementInvalid, "can't quote Hash"
          end
        end

        def method_missing(method, *args, &block)
          if @klass.respond_to?(method)
            scoping { @klass.public_send(method, *args, &block) }
          else
            super
          end
        end
      end
    end
  end
end
