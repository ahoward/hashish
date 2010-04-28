begin
  ActiveRecord
  ActiveRecord::Base
rescue NameError
  nil
end

if defined?(ActiveRecord)

  module ActiveRecord
    module ToHashish
      module ClassMethods
        def to_hashish(*args)

          @to_hashish ||= (
            column_names # + reflect_on_all_associations.map(&:name)
          ).map{|name| name.to_s}

          unless args.empty?
            @to_hashish.clear
            args.flatten.compact.each do |arg|
              @to_hashish.push(arg.to_s)
            end
            @to_hashish.uniq!
            @to_hashish.map!{|name| name.to_s}
          end

          @to_hashish
        end
        alias_method 'to_h', 'to_hashish'

        def to_hashish=(*args)
          to_hashish(*args)
        end
      end

      module InstanceMethods
        def to_hashish(*args)
          hash = Hashish.data
          model = self.class

          attrs = args.empty? ? model.to_hashish : args

          attrs.each do |attr|
            value = send(attr)

            if value.respond_to?(:to_hashish)
              hash[attr] = value.to_hashish
              next
            end

            if value.is_a?(Array)
              hash[attr] = value.map{|val| val.respond_to?(:to_hashish) ? val.to_hashish : val}
              next
            end

            hash[attr] = value
          end

          if hash.has_key?(:_id) and not hash.has_key?(:id)
            hash[:id] = hash[:_id]
          end

          hash
        end
        alias_method 'to_h', 'to_hashish'
      end
    end

    ActiveRecord::Base.send(:extend, ToHashish::ClassMethods)
    ActiveRecord::Base.send(:include, ToHashish::InstanceMethods)
  end

end
