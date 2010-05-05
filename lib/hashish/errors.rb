module Hashish
  class Errors < HashWithIndifferentAccess
    include HashMethods

    include Tagz.globally
    extend Tagz.globally

    Global = '*' unless defined?(Global)
    Separator = ':' unless defined?(Separator)

    class Message < ::String
      attr_accessor :sticky

      def initialize(*args)
        options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
        replace(args.join(' '))
        @sticky = options[:sticky]
      end

      def sticky?
        @sticky ||= nil
        !!@sticky
      end

      def to_yaml(*args, &block)
        to_str.to_yaml(*args, &block)
      end
    end

    def to_yaml(*args, &block)
      Hash.new.update(self).to_yaml(*args, &block)
    end

    def Errors.global_key
      [Global]
    end

    attr 'data'

    def initialize(data = Hashish.data)
      @data = data
    end

    def status(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      sticky = options.has_key?(:sticky) ? options[:sticky] : true
      status = Status.for(*args)
      msg = Message.new(status, :sticky => sticky)
      key = 'Status'
      delete(key)
      add(key, msg) unless status.ok?
      status
    end

    def status=(*args)
      status(*args)
    end

    def add(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      sticky = options[:sticky]
      clear = options[:clear]

      args.flatten!
      message = args.pop
      keys = args
      keys = [Global] if keys.empty?
      errors = Hash.new

      if Array(keys) == [Global]
        sticky = true unless options.has_key?(:sticky)
      end

      sticky = true if(message.respond_to?(:sticky?) and message.sticky?)

      if message
        if message.respond_to?(:full_messages)
          message.depth_first_each do |keys, msg|
            errors[keys] = Message.new(msg, :sticky => sticky)
          end
        else
          errors[keys] = Message.new(message, :sticky => sticky)
        end
      end

      result = []

      errors.each do |keys, message|
        list = get(keys)
        unless get(keys)
          set(keys => [])
          list = get(keys)
        end
        list.clear if clear
        list.push(message)
        result = list
      end
      
      result
    end
    alias_method 'add_to_base', 'add'

    def add!(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      options[:sticky] = true
      args.push(options)
      add(*args)
    end
    alias_method 'add_to_base!', 'add!'

    alias_method 'clear!', 'clear' unless instance_methods.include?('clear!')

    def clear
      keep = []
      depth_first_each do |keys, message|
        index = keys.pop
        args = [keys, message].flatten
        keep.push(args) if message.sticky?
      end
      clear!
    ensure
      keep.each{|args| add!(*args)}
    end

    def invalid?(*keys)
      !get(keys).nil?
    end

    alias_method 'on?', 'invalid?'

    alias_method 'on', 'get'

    def depth_first_each(*args, &block)
      Hashish.depth_first_each(enumerable=self, *args, &block)
    end

    def size
      size = 0
      Hashish.depth_first_each(enumerable=self){ size += 1 }
      size
    end

    alias_method 'count', 'size'
    alias_method 'length', 'size'

    def full_messages
      full_messages = []

      depth_first_each do |keys, value|
        index = keys.pop
        key = keys.join('.')
        value = value.to_s
        next if value.strip.empty?
        full_messages.push([key, value])
      end

      full_messages.sort! do |a,b|
        a, b = a.first, b.first
        if a == Global
          b == Global ? 0 : -1
        elsif b == Global
          a == Global ? 0 : 1
        else
          a <=> b
        end
      end

      full_messages
    end

    def each_message
      depth_first_each do |keys, message|
        index = keys.pop
        message = message.to_s.strip
        next if message.empty?
        yield(keys, message)
      end
    end

    def each_full_message
      full_messages.each{|msg| yield msg}
    end

    alias_method 'each_full', 'each_full_message'

    def messages
      messages =
        (self[Global]||[]).map{|message| message}.
        select{|message| not message.strip.empty?}
    end

    def to_html(*args)
      Errors.to_html(errors=self, *args)
    end

    def Errors.to_html(*args, &block)
      if block
        define_method(:to_html, &block)
      else
        errors_to_html(*args)
      end
    end

    def Errors.errors_to_html(*args)
      error = args.shift
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      errors = [error, *args].flatten.compact

      at_least_one = false
      names = errors.map{|e| e.data._name}
      klass = [names, 'hashish errors'].flatten.compact.join(' ')

      html =
        ul_(:class => klass){
          __
          h4_(:class => 'caption'){ 'Sorry, there were some errors.' }
          __

          errors.each do |e|
            e.full_messages.each do |key, value|
              at_least_one = true
              key = key.to_s
              if key == Global
                # value = value.respond_to?(:humanize) ? value.humanize: value.capitalize
                li_(:class => 'all'){ span_(:class => :message){ value } }
              else
                # key = key.respond_to?(:humanize) ? key.humanize: key.capitalize
                li_(:class => 'field'){
                  span_(:class => 'field'){ key }
                  span_(:class => 'separator'){ Separator }
                  span_(:class => 'message'){ value }
                }
              end
              __
            end
          end
        }

      at_least_one ? html : ''
    end

    def to_s(*args, &block)
      to_html(*args, &block)
    end
  end
end
