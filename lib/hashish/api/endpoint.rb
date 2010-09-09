module Hashish
  module Endpoint
    attr_accessor :name
    attr_accessor :description
    attr_accessor :signature

    def Endpoint.extend_object(object)
      super
    end
  end
end
