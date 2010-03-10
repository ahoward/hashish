module Hashish
  class Data < HashWithIndifferentAccess
    include HashMethods

    attr_accessor :name
    attr_accessor :errors
    attr_accessor :form
    attr_writer :status

    def initialize(*args, &block)
      data = self
      options = args.last.is_a?(Hash) ? args.pop : {}

      @name = 
        case args.size
          when 0
            options.keys.first if options.size==1
          else
            args.shift
        end
      @name ||= (options.is_a?(Data) ? options.name : 'data')

      @errors = Errors.new(data)
      @form = Form.new(data)
      @status = Status.ok

      super(options)
    end

    def status
      Status.for(@status)
    end

    alias_method 'error', 'errors'
    alias_method 'f', 'form'

    def valid?()
      errors.empty? and status.ok?
    end

    def id
      self[:id] || self[:_id]
    end

    def new_record?
      !!id
    end

    def model_name
      name.to_s
    end

    def parse(params = {})
      Hashish.parse(name, params)
    end

    def apply(other)
      Data.apply(other => self)
    end

    alias_method 'build', 'apply'

    class << Data
      def apply(*args)
        if args.size == 1 and args.first.is_a?(Hash)
          params, schema = args.first.to_a.flatten
        else
          params, schema, *ignored = args
        end

        params = Hashish.data(schema.name, params)
        result = Hashish.data(schema.name, schema)

        Hashish.depth_first_each(params) do |keys, val|
          #currently = result.get(keys)
          result.set(keys => val) #if(currently.nil? or currently.empty?)
        end

        result
      end

      def build(*args)
        name = args.shift
        result = apply(*args)
        result.name = name
        result
      end
    end
  end

  def data(*args, &block)
    #args.push(:data) if args.empty? and block.nil?
    data = Hashish::Data.new(*args)
    block.call(data) if block
    data
  end

  alias_method 'hash', 'data'
end
