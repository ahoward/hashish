module Hashish
  class Errors < HashWithIndifferentAccess
    include HashMethods
    include Tagz.globally
    extend Tagz.globally

    All = '*' unless defined?(All)
    Separator = ':' unless defined?(Separator)

    attr 'data'

    def initialize(data = Hashish.data)
      @data = data
    end

    def add(*args)
      options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})

      args.flatten!
      message = args.pop
      keys = args
      keys = [All] if keys.empty?

      if message
        if message.respond_to?(:full_messages)
          message.each do |key, msg|
            options[key] = msg.to_s
          end
        else
          options[keys] = message.to_s
        end
      end

      options.each do |keys, message|
        list = get(keys)
        unless get(keys)
          set(keys => [])
          list = get(keys)
        end
        list.push(message)
      end
    end

    alias_method 'add_to_base', 'add'

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
        if a == All
          b == All ? 0 : -1
        elsif b == All
          a == All ? 0 : 1
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
        (self[All]||[]).map{|message| message.to_s}.
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
                if key == All
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
              if key == All
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
