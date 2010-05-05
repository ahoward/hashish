module Hashish
  class Api

  # mode support
  #
    def Api.new(*args, &block)
      api = allocate
      api.instance_eval do
        @mode = Mode.for(:read)
        @catching = false
        initialize(*args, &block)
      end
      api
    end

    class Mode < ::String
      class << Mode
        def for(mode)
          mode.is_a?(Mode) ? mode : Mode.new(mode.to_s)
        end
      end

      Write = Mode.for(:write) unless defined?(Write)
      Read = Mode.for(:read) unless defined?(Read)
      Post = Write unless defined?(Post)
      Get = Read unless defined?(Get)
      Default = Read unless defined?(Default)

      class << Mode
        %w( read write get post default ).each do |method|
          define_method(method){ const_get(method.capitalize) }
        end
      end

      def ==(other)
        super(Mode.for(other))
      end
    end


    def mode=(mode)
      @mode = Mode.for(mode)
    end

    def mode(*args, &block)
      @mode ||= Mode.default

      if args.empty? and block.nil?
        @mode
      else
        if block
          mode = self.mode
          self.mode = args.shift
          begin
            instance_eval(&block)
          ensure
            self.mode = mode
          end
        else
          self.mode = args.shift
        end
        self
      end
    end

    def mode?(mode, &block)
      condition = self.mode == mode

      if block.nil?
        condition
      else
        if condition
          result = block.call
          throw(:result, result) if catching?
          result
        end
      end
    end

    def Api.modes(*modes)
      @modes ||= []
      modes.flatten.compact.map{|mode| Api.add_mode(mode)} unless modes.empty?
      @modes
    end

    def Api.add_mode(mode)
      modes.push(mode = Mode.for(mode)).uniq!

      module_eval <<-__
        def #{ mode }(&block)
          mode(#{ mode.inspect }, &block)
        end
        def #{ mode }?(&block)
          mode?(#{ mode.inspect }, &block)
        end
      __

      mode
    end

    Api.modes('read', 'write')

    alias_method 'get', 'read'
    alias_method 'get?', 'read?'

    alias_method 'post', 'write'
    alias_method 'post?', 'write?'


    def catching(label = :result, &block)
      catching = @catching
      @catching = true
      catch(label, &block)
    ensure
      @catching = catching
    end

    def catching?
      @catching
    end

    def params(*args)
      @params ||= Hashish.hash
      @params.update(*args) unless args.empty?
      @params
    end

    def schema(*args)
      @schema ||= Hashish.hash
      @schema.update(*args) unless args.empty?
      @schema
    end

    def result
      @result ||= (schema + params)
    end

    alias_method 'h', 'result'

# TODO - namespcaes are not recursive yet
# TODO - endpoints are not listed on the top level appropriately
#
  # endpoint support
  #
    module Endpoints
      def endpoint(name, &block)
        name = name.to_s
        endpoint = name + '_endpoint'

        define_method(name) do |*args|
          @params = Hashish.hash(args.last.is_a?(Hash) ? args.pop : {})
          args.push(@params)
          caught = catching{ send(endpoint, *args) }
          return(Data === caught ? caught : result)
        end

        define_method(endpoint, &block)
        public(name)
      ensure
        (endpoints << name).uniq!
      end

      alias_method('Endpoint', 'endpoint')

      def endpoints
        @endpoints ||= []
      end
    end

  # namespace support
  #
    attr_accessor :namespace

    class Namespace < Module
      attr_accessor :parent
      attr_accessor :name

      def Namespace.new(parent, name, &block)
        namespace = super(&block)
        namespace.parent = parent
        namespace.name = name
        namespace
      end

      def method_added(method)
        private(method)
      end

      def inspect
        "Namespace(#{ name })"
      end
      
      include Endpoints
    end

    class << Api
      def namespace(name, &block)
        name = name.to_s.downcase.strip

        namespace = namespaces[name]
        parent = self

        if block
          if namespace
            namespace.module_eval(&block)
          else
            namespace = Namespace.new(parent, name, &block)
            namespaces[name] = namespace

            module_eval <<-__
              def #{ name }(&block)
                namespaced = self.dup
                namespace = self.class.namespaces[#{ name.inspect }]
                namespaced.extend(namespace)
                namespaced.namespace = namespace
                if block
                  namespaced.instance_eval(&block)
                else
                  namespaced
                end
              end
            __
          end
        end

        namespace
      end
      alias_method 'Namespace', 'namespace'

      def namespaces
        @namespaces ||= Hash.new
      end

      include Endpoints
    end
  end

  def api(&block)
    block ? Class.new(Api, &block) : Api
  end
end
