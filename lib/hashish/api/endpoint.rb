module Hashish
  module Endpoint
    attr_accessor :name
    attr_accessor :description
    attr_accessor :params

    def Endpoint.extend_object(object)
      super
    end
  end
end
