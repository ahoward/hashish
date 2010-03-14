module Hashish
  class Validations < HashWithIndifferentAccess
    include HashMethods

    class Callback < ::Proc
      attr :options

      def initialize(options = {}, &block)
        @options = Hashish.hash_for(options || {})
        super(&block)
      end
    end

    attr 'data'

    def initialize(data = Hashish.data)
      @data = data
    end

    def errors
      data.errors
    end

    def each(&block)
      Hashish.depth_first_each(enumerable=self, &block)
    end

    def size
      size = 0
      Hashish.depth_first_each(enumerable=self){ size += 1 }
      size
    end

    alias_method 'count', 'size'
    alias_method 'length', 'size'

    def run!
      errors.clear
      run
    end

    def run
      depth_first_each do |keys, callback|
        next unless callback and callback.respond_to?(:to_proc)
        value = data.get(keys)
        valid = !!data.instance_exec(value, &callback)
        message = callback.options[:message] || 'is invalid.'
        errors.add(keys, message) unless valid
      end
      return self
    end

    def add(*args, &block)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      callback = Validations::Callback.new(options, &block)
      args.push(callback)
      set(*args)
p :add => self
    end
  end
end
