# frozen_string_literal: true

require_relative 'scope_registry'
require_relative 'relation'

module Aliyun
  module Log
    module Record
      module Scoping
        extend ActiveSupport::Concern

        module ClassMethods
          delegate :load, :result, :count, :sum, to: :all
          delegate :where, :query, :search, :sql, :from, :to, :api,
                   :page, :line, :limit, :offset, :select, :group,
                   :order, :to_sql, to: :all
          delegate :first, :last, :second, :third, :fourth, :fifth, :find_offset, to: :all

          def current_scope
            ScopeRegistry.value_for(:current_scope, self)
          end

          def current_scope=(scope)
            ScopeRegistry.set_value_for(:current_scope, self, scope)
          end

          def scope(name, body)
            raise ArgumentError, 'The scope body needs to be callable.' unless body.respond_to?(:call)

            singleton_class.send(:define_method, name) do |*args|
              scope = all
              scope = scope.scoping { body.call(*args) }
              scope
            end
          end

          def unscoped
            block_given? ? relation.scoping { yield } : relation
          end

          def all
            scope = current_scope
            scope ||= relation.from(0).to(Time.now.to_i)
            scope
          end

          private

          def relation
            Relation.new(self)
          end
        end
      end
    end
  end
end
