class Error < ::StandardError
  class Empty < Error; end
  class Ambiguous < Error; end
end
