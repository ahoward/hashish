module Hashish
  class Data < HashWithIndifferentAccess
    include HashMethods

    attr_accessor :name
    attr_accessor :errors
    attr_accessor :validations
    attr_reader :form

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
      @validations = Validations.new(data)
      @form = Form.new(data)
      @status = Status.ok

      super(options)
    end

    def status(*args)
      unless args.empty?
        options = Hashish.hash_for(args.last.is_a?(Hash) ? args.pop : {})
        @status = Status.for(*args)
        @errors.status(@status, options)
      end
      @status
    end

    def status=(*args)
      status(*args)
    end

    def form(*args, &block)
      return @form if(args.empty? and block.nil?)
      @form.form(*args, &block)
    end

    alias_method 'error', 'errors'

    def validates(*args, &block)
      validations.add(*args, &block)
    end

    def validate
      validations.run
      errors.empty?
    end

    def valid?(options = {})
      validate and errors.empty? and status.ok?
    end

    def validate!
      validations.run!
      errors.empty?
    end

    def valid!(options = {})
      validate! and errors.empty? and status.ok?
    end

    def id
      self[:id] || self[:_id]
    end

    def new_record?
      !!id
    end

    alias_method 'new?', 'new_record?'

    def blank?
      depth_first_each do |keys, value|
        is_blank = 
          if value.respond_to?(:blank?)
            value.blank?
          else
            case value
              when 0, 0.0, nil, false, '', [], {}
                true
              when String
                value.strip.empty?
              when Array
                value.join.empty?
              when Numeric
                value.to_i == 0
            end
          end
        return false unless is_blank
      end
      return true
    end

    def type
      self[:type] || self[:_type] || super
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
    alias_method '+', 'apply'

    def to_yaml(*args, &block)
      Hash.new.update(self).to_yaml(*args, &block)
    end

    unless Object.new.respond_to?(:instance_exec)
      module InstanceExecHelper; end
      include InstanceExecHelper

      def instance_exec(*args, &block)
        begin
          old_critical, Thread.critical = Thread.critical, true
          n = 0
          n += 1 while respond_to?(mname="__instance_exec_#{ n }__")
          InstanceExecHelper.module_eval{ define_method(mname, &block) }
        ensure
          Thread.critical = old_critical
        end
        begin
          ret = send(mname, *args)
        ensure
          InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
        end
        ret
      end
    end

    Apply = Struct.new(:blacklist, :whitelist).new([], [])

    class << Data
      def apply_whitelist
        Apply.whitelist
      end

      def apply_blacklist
        Apply.blacklist
      end

      def apply(*args)
        if args.size == 1 and args.first.is_a?(Hash)
          updates, hash = args.first.to_a.flatten
        else
          updates, hash, *ignored = args
        end

        updates = Hashish.data(hash.name, updates)
        result = Hashish.data(hash.name, hash)

        blacklist = Apply.blacklist
        whitelist = Apply.whitelist

        updates.depth_first_each do |keys, val|
          unless whitelist.empty?
          end

          unless blacklist.empty?
          end

          next if keys.compact.empty?
          next if val.nil?

          result.set(keys => val)
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

  alias_method 'data_for', 'data'
  alias_method 'hash', 'data'
  alias_method 'schema', 'data'
end
