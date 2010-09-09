module Hashish
  class Api
    class << Api
      def Api.new(*args, &block)
        api = allocate
        api.instance_eval do
          before_initialize(*args, &block)
          initialize(*args, &block)
          after_initialize(*args, &block)
        end
        api
      end

      def modes(*modes)
        @modes ||= []
        modes.flatten.compact.map{|mode| Api.add_mode(mode)} unless modes.empty?
        @modes
      end

      def add_mode(mode)
        modes.push(mode = Mode.for(mode)).uniq!
        module_eval(<<-__, __FILE__, __LINE__ - 1)
          def #{ mode }(&block)
            mode(#{ mode.inspect }, &block)
          end
          def #{ mode }?(&block)
            mode?(#{ mode.inspect }, &block)
          end
        __
        mode
      end

      def path_for(*paths)
        path = [*paths].flatten.compact.join('/')
        path.squeeze!('/')
        path.sub!(%r|^/|, '')
        path.sub!(%r|/$|, '')
        path.split('/')
      end

      def absolute_path_for(*paths)
        '/' + path_for(*paths).join('/')
      end

      def evaluate(&block)
        @dsl ||= DSL.new(api=self)
        @dsl.evaluate(&block)
      end

      def endpoints
        @endpoints ||= Array.fields
      end

      def get(*names)
        name = Api.absolute_path_for(*names)
        endpoint = endpoints[name]
        raise(NameError, name) unless endpoint
        endpoint
      end

      alias_method '[]', 'get'
    end

    Api.modes('read', 'write')

    def before_initialize(*args, &block)
      @mode = Mode.for(:read)
      @catching = false
    end

    def after_initialize(*args, &block)
      :hook
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

    def absolute_path_for(*paths)
      Api.absolute_path_for(*paths)
    end

    def endpoints
      unless defined?(@endpoints)
        @endpoints ||= Array.fields
        self.class.endpoints.each do |endpoint|
          @endpoints[endpoint.name] = endpoint.bind(self)
        end
      end
      @endpoints
    end

    def get(*names)
      name = Api.absolute_path_for(*names)
      endpoint = endpoints[name]
      raise(NameError, name) unless endpoint
      endpoint
    end

    alias_method '[]', 'get'

    def call(path, *args)
      get(path).call(*args)
    end
  end

  def api(&block)
    if block
      api = Class.new(Api)
      api.evaluate(&block)
      api
    else
      Api
    end
  end
end
