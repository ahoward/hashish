module Hashish
  module ParameterParser
    def parse_params(key = 'data', hash = {}, &block)
      key = key.to_s
      data = Hashish::Data.new(key)
      hash = HashWithIndifferentAccess.new.update(hash)
      base = hash[key]
      data.update(base) if base

      key = data.key
      re = %r/^ #{ Regexp.escape(key) } (?: [(] ([^)]+) [)] )? $/x
      missing = true

      hash.each do |key, value|
        next unless(key.is_a?(String) or key.is_a?(Symbol))
        key = key.to_s
        match, keys = re.match(key).to_a
        next unless match
        next unless keys
        keys = keys.strip.split(%r/\s*,\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
        data.set(keys => value)
        missing = false
      end

      block.call(data) if(block and missing)

      data
    end

    alias_method 'parse', 'parse_params'
  end

  extend ParameterParser
end
