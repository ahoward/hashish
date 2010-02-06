module Hashish
  module Options
    def to_options!
      replace to_options
    end

    def to_options
      keys.inject(Hash.new){|h,k| h.update k.to_s.to_sym => fetch(k)}
    end
          
    def getopt key, default = nil
      [ key ].flatten.each do |key|
        return fetch(key) if has_key?(key)
        key = key.to_s
        return fetch(key) if has_key?(key)
        key = key.to_sym
        return fetch(key) if has_key?(key)
      end
      default
    end
    alias_method 'get_opt', 'getopt'
    alias_method 'get_opt?', 'getopt'

    def getopts *args
      args.flatten.map{|arg| getopt arg}
    end
    alias_method 'get_opts', 'getopts'
    alias_method 'get_opts?', 'getopts'

    def hasopt key, default = nil
      [ key ].flatten.each do |key|
        return true if has_key?(key)
        key = key.to_s
        return true if has_key?(key)
        key = key.to_sym
        return true if has_key?(key)
      end
      default
    end
    alias_method 'hasopt?', 'hasopt'
    alias_method 'has_opt?', 'hasopt'

    def hasopts *args
      args.flatten.map{|arg| hasopt arg}
    end
    alias_method 'hasopts?', 'hasopts'
    alias_method 'has_opts?', 'hasopts'

    def delopt key, default = nil
      [ key ].flatten.each do |key|
        return delete(key) if has_key?(key)
        key = key.to_s
        return delete(key) if has_key?(key)
        key = key.to_sym
        return delete(key) if has_key?(key)
      end
      default
    end
    alias_method 'del_opt', 'delopt'
    alias_method 'del_opt?', 'delopt'

    def delopts *args
      args.flatten.map{|arg| delopt arg}
    end
    alias_method 'del_opts', 'delopts'
    alias_method 'del_opts?', 'delopts'

    def setopt key, value = nil
      [ key ].flatten.each do |key|
        return self[key]=value if has_key?(key)
        key = key.to_s
        return self[key]=value if has_key?(key)
        key = key.to_sym
        return self[key]=value if has_key?(key)
      end
      return self[key]=value
    end
    alias_method 'setopt!', 'setopt'
    alias_method 'set_opt!', 'setopt'

    def setopts opts 
      opts.each{|key, value| setopt key, value}
      opts
    end
    alias_method 'setopts!', 'setopts'
    alias_method 'set_opts!', 'setopts'

    def select! *a, &b
      replace select(*a, &b).to_hash
    end
  end

  def Options.for(hash)
    hash =
      case hash
        when Hash
          hash
        when Array
          Hash[*hash.flatten]
        when String, Symbol
          {hash => true}
        else
          hash.to_hash
      end
  ensure
    hash.extend(Options) unless hash.is_a?(Options)
  end
end
