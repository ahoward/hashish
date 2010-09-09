module Hashish
  class Api
    class Mode < ::String
      class << Mode
        def for(mode)
          mode.is_a?(Mode) ? mode : Mode.new(mode.to_s)
        end
      end

      Write = Mode.for(:write) unless defined?(Write)
      Read = Mode.for(:read) unless defined?(Read)
      Post = Write unless defined?(Post)
      Get = Read unless defined?(Get)
      Default = Read unless defined?(Default)

      class << Mode
        %w( read write get post default ).each do |method|
          define_method(method){ const_get(method.capitalize) }
        end
      end

      def ==(other)
        super(Mode.for(other))
      end
    end
  end
end
