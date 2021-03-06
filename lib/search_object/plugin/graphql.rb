# frozen_string_literal: true

module SearchObject
  module Plugin
    module Graphql
      def self.included(base)
        raise NotIncludedInResolverError, base unless base.ancestors.include? GraphQL::Schema::Resolver

        base.include SearchObject::Plugin::Enum
        base.extend ClassMethods
      end

      attr_reader :object, :context

      def initialize(filters: {}, object: nil, context: {}, scope: nil, field: nil)
        @object = object
        @context = context

        super filters: filters, scope: scope, field: field
      end

      # NOTE(rstankov): GraphQL::Schema::Resolver interface
      # Documentation - http://graphql-ruby.org/fields/resolvers.html#using-resolver
      def resolve_with_support(args = {})
        self.params = args.to_h
        results
      end

      module ClassMethods
        def option(name, options = {}, &block)
          type = options.fetch(:type) { raise MissingTypeDefinitionError, name }
          options[:enum] = type.values.map { |value, enum_value| enum_value.value || value } if type.respond_to?(:values)

          argument(
            name.to_s,
            options[:type],
            required: options[:required] || false,
            description: options[:description],
            camelize: options[:camelize]
          )

          super(name, options, &block)
        end

        def types
          GraphQL::Define::TypeDefiner.instance
        end
      end

      class NotIncludedInResolverError < ArgumentError
        def initialize(base)
          super "#{base.name} should inherit from GraphQL::Schema::Resolver. Current ancestors #{base.ancestors}"
        end
      end

      class MissingTypeDefinitionError < ArgumentError
        def initialize(name)
          super "GraphQL type has to passed as :type to '#{name}' option"
        end
      end
    end
  end
end
