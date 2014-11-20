require_relative 'finders'
require_relative 'associations'

module Zabbirc
  module Zabbix

    IDNotUniqueError = Class.new(StandardError)

    module Resource
      class Base
        extend Finders, Associations

        def self.set_model_name model_name
          @model_name = model_name
        end

        def self.model_name
          @model_name ||= name.split(/::/).last.underscore
        end

        def self.api
          Connection.get_connection.client
        end

        def api
          Connection.get_connection.client
        end

        def initialize attrs
          @attrs = ActiveSupport::HashWithIndifferentAccess.new attrs
          raise ArgumentError, "attribute `#{self.class.model_name}id` not found, probably not an Event" unless @attrs.key? :"#{self.class.model_name}id"
        end

        def id
          @attrs["#{self.class.model_name}id"]
        end

        def [] attr
          @attrs[attr]
        end

        def method_missing method, *args, &block
          if args.length == 0 and not block_given? and @attrs.key? method
            @attrs[method]
          else
            super
          end
        end
      end
    end
  end
end