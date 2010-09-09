module Hashish
  class Api
    class DSL < BlankSlate
      attr_accessor :api

      def initialize(api)
        @api = api
      end

      def evaluate(&block)
        Object.instance_method(:instance_eval).bind(self).call(&block)
      end

      def endpoint(*paths, &block)
        name = api.absolute_path_for(*paths) 

        api.module_eval{ 
          define_method(name + '/endpoint', &block)

          define_method(name) do |*args|
            # setup
            send(name + '/endpoint', *args)
            # teardown
          end

          public name
        }

        endpoint = api.instance_method(name)
        endpoint.extend(Endpoint)
        endpoint.name = name
        api.endpoints[endpoint.name] = endpoint

        #@params = Hashish.hash(args.last.is_a?(Hash) ? args.pop : {})
        #args.push(@params)
        #caught = catching{ send(endpoint, *args) }
        #return(Data === caught ? caught : result)
        #caught
        #caught = catching{ send(endpoint, *args) }
      ensure
      end

      alias_method('Endpoint', 'endpoint')
    end
  end
end
