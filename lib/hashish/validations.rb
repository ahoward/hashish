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

    Cleared = '___CLEARED___'.freeze unless defined?(Cleared)

    def run
      previous_errors = []
      new_errors = []

      errors.each_message do |keys, message|
#p :keys => keys
#p :message => message
        previous_errors.push([keys, message])
      end

#p :previous_errors => previous_errors
      errors.clear

      depth_first_each do |keys, callback|
        next unless callback and callback.respond_to?(:to_proc)

        value = data.get(keys)
        valid = !!data.instance_exec(value, &callback)
        message = callback.options[:message] || 'is invalid.'

        unless valid
          new_errors.push([keys, message])
        else
          new_errors.push([keys, Cleared])
        end
      end

#p :new_errors => new_errors

      previous_errors.each do |keys, message|
        errors.add(keys, message) unless new_errors.assoc(keys)
      end

      new_errors.each do |keys, value|
        next if value == Cleared
        message = value
        errors.add(keys, message)
      end

#p :errors => errors

      return self
    end

    def run!
      errors.clear!
      run
    end

    def add(*args, &block)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      block = args.pop if args.last.respond_to?(:call)
      callback = Validations::Callback.new(options, &block)
      args.push(callback)
      set(*args)
    end
  end
end
