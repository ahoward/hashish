module Hashish
  class Api
    class DSL < BlankSlate
      attr_accessor :api

      def initialize(api)
        @api = api
        @evaluate = Object.instance_method(:instance_eval).bind(self)
      end

      def evaluate(&block)
        @evaluate.call(&block)
      end

      def endpoint(*args, &block)
        api.endpoint(*args, &block)
      end

      alias_method('Endpoint', 'endpoint')
    end
  end
end
