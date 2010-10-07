module Hashish
  class OrderedHash < Map
    def convert_value(value)
      return value.to_hashish if value.respond_to?(:to_hashish)
      super
    end
  end
end
