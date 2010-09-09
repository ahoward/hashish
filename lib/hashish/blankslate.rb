module Hashish
  class BlankSlate
    instance_methods.each{|m| undef_method(m) unless m.to_s =~ /^__/}
  end
end
