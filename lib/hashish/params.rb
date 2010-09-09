module Hashish
  module Params
    def parse(*args, &block)
      hash = args.last.is_a?(Hash) ? args.pop : {}
      name = args.empty? ? 'data' : args.shift
      name = name.to_s
      data = Hashish::Data.new(name)
      hash = HashWithIndifferentAccess.new.update(hash)
      base = hash[name]
      data.update(base) if base

      name = data.name
      re = %r/^ #{ Regexp.escape(name) } (?: [(] ([^)]+) [)] )? $/x
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

    extend Params
  end


  def Hashish.parse(*args, &block)
    Params.parse(*args, &block)
  end
end
