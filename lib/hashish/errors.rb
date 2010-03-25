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
    end

    attr 'data'

    def initialize(data = Hashish.data)
      @data = data
    end

    def add(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      sticky = options[:sticky]

      args.flatten!
      message = args.pop
      keys = args
      keys = [Global] if keys.empty?
      errors = Hash.new

      if Array(keys) == [Global]
        sticky = true unless options.has_key?(:sticky)
      end

      if message
        if message.respond_to?(:full_messages)
          message.each do |key, msg|
            errors[key] = Message.new(msg, :sticky => sticky)
          end
        else
          errors[keys] = Message.new(message, :sticky => sticky)
        end
      end

      errors.each do |keys, message|
        list = get(keys)
        unless get(keys)
          set(keys => [])
          list = get(keys)
        end
        list.push(message)
      end
    end
    alias_method 'add_to_base', 'add'

    def add!(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
      options[:sticky] = true
      args.push(options)
      add(*args)
    end
    alias_method 'add_to_base!', 'add!'

    alias_method 'clear!', 'clear'

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

    def each_full
      full_messages.each{|msg| yield msg}
    end

    def messages
      messages =
        (self[Global]||[]).map{|message| message}.
        select{|message| not message.strip.empty?}
    end

    def each_message
      messages.each{|msg| yield msg}
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
        table_(:class => klass){
          caption_(:style => 'white-space:nowrap'){ 'Sorry, there were some errors.' }

          tbody_{
            errors.each do |e|
              e.full_messages.each do |key, value|
                at_least_one = true
                key = key.to_s
                if key == Global
                  # value = value.respond_to?(:humanize) ? value.humanize: value.capitalize
                  tr_(:colspan => 3){
                    td_(:class => 'all'){ value }
                  }
                else
                  # key = key.respond_to?(:humanize) ? key.humanize: key.capitalize
                  tr_{
                    td_(:class => 'field'){ key }
                    td_(:class => 'separator'){ Separator }
                    td_(:class => 'message'){ value }
                  }
                end
              end
            end
          }
        }

      at_least_one ? html : ''
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
          h4_(:class => 'caption'){ 'Sorry, there were some errors.' }

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
