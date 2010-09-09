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

    def route(*args, &block)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      mode = options[:mode] || Mode.read

      route = [args].flatten.compact.join('/').split('/')
      namespaces, endpoint = route, route.pop

      target = send(mode)
      namespaces.each{|namespace| target = target.send(namespace)}

      target.send(endpoint, params)
    end

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

    class Namespace < BlankSlate
      def initialize(api, scope = [])
        @api = api
        @scope = scope
      end

      def inspect
        "#{ self.class.name }(#{ @scope.join('/').inspect })"
      end

      def class
        Namespace
      end

      def method_missing(method, *args, &block)
        method = method.to_s
        message = [@scope, method].join('/')
        if @api.respond_to?(message)
          @api.send(message, *args, &block)
        else
          Namespace.new(@api, @scope + [method])
        end
      end
    end

    class << Api
      def path_for(*names)
        path = [*names].flatten.compact.join('/')
        path.squeeze!('/')
        path.sub!(%r|^/|, '')
        path.sub!(%r|/$|, '')
        path.split('/')
      end

      def endpoint(*names, &block)
        path = path_for(scope, *names) 

        if path.size > 1
          namespace = path.first
          unless instance_methods.detect{|m| m.to_s == namespace}
            define_method(namespace){ Namespace.new(api=self, [namespace]) }
          end
        end

        scoped = path.join('/')

        endpoint = [scoped, 'endpoint'].join('/')
        define_method(endpoint, &block)

        define_method(scoped) do |*args|
          @params = Hashish.hash(args.last.is_a?(Hash) ? args.pop : {})
          args.push(@params)
          caught = catching{ send(endpoint, *args) }
          #return(Data === caught ? caught : result)
          caught
        end

        public(scoped)
      ensure
        (endpoints << scoped).uniq!
      end

      alias_method('Endpoint', 'endpoint')

      def endpoints
        @endpoints ||= []
      end

      def scope
        @scope ||= []
      end

      def namespaces
        @namespaces ||= Hash.new
      end

      def namespace(name, &block)
        name = name.to_s

=begin
        top = scope.empty?
        if top
          unless respond_to?(name)
            define_method(name){ Namespace.new(api=self, [name]) }
          end
        end
=end

        begin
          scope.push(name)
          block.call(scope)
        ensure
          scope.pop
        end
      end
    end
  end

  def api(&block)
    block ? Class.new(Api, &block) : Api
  end
end
