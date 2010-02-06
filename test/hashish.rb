require 'hashish'

Testing Hashish do

# data
#
  testing 'basic data can be constructed' do
    data = assert{ Hashish.data.new }
  end
  testing 'basic data can be constructed with a key' do
    data = assert{ Hashish.data.new('key') }
    assert{ data.key == 'key' }
  end
  testing 'data can be constructed with values' do
    data = assert{ Hashish.data.new(:key => :value) }
    #assert{ data.key == nil }
    #assert{ data._id == nil }
    assert{ data =~ {:key => :value} }
  end
  testing 'indifferent access' do
    data = assert{ Hashish.data.new(:key => :value) }
    assert{ data =~ {:key => :value} }
    assert{ data[:key] == :value }
    assert{ data['key'] == :value }
  end
  testing 'nested indifferent access' do
    data = assert{ Hashish.data.new(:a => {:b => :value}) }
    assert{ data =~ {:a => {:b => :value}} }
    assert{ data[:a] =~ {:b => :value} }
    assert{ data['a'] =~ {:b => :value} }
    assert{ data[:a][:b] == :value }
    assert{ data[:a]['b'] == :value }
  end
  testing 'deeply nested indifferent access' do
    data = assert{ Hashish.data.new(:x => {:y => {:z => :value}}) }
    assert{ data =~ {:x => {:y => {:z => :value}}} }
    assert{ data[:x] =~ {:y => {:z => :value}} }
    assert{ data['x'] =~ {:y => {:z => :value}} }
    assert{ data[:x][:y] =~ {:z => :value} }
    assert{ data[:x]['y'] =~ {:z => :value} }
    assert{ data[:x][:y][:z] == :value }
    assert{ data[:x][:y]['z'] == :value }
  end
  testing 'setting/getting a deeply nested value' do
    data = assert{ Hashish.data.new }
    assert{ data.set([:a,:b,:c] => 42) }
    assert{ data =~ {:a => {:b => {:c => 42}}} }
    assert{ data.get(:a,:b,:c) == 42 }
  end
  testing 'setting/getting a deeply nested array' do
    data = assert{ Hashish.data.new }
    assert{ data.set([:a,:b,0] => 40) }
    assert{ data.set([:a,:b,1] => 2) }
    assert{ data =~ {:a => {:b => [40,2]}} }
    assert{ data.get(:a,:b) == [40,2] }
  end
  testing 'depth first traversal' do
    data = assert{ Hashish.data.new }
    assert{ data.set(:A => 42) }
    assert{ data.set(:Z => 42.0) }
    assert{ data.set([:a,:b,0] => 40) }
    assert{ data.set([:a,:b,1] => 2) }

    pairs = []
    assert{
      data.depth_first_each do |keys, val|
        pairs.push([keys, val])
      end
      true
    }
    expected = [
      [["A"], 42],
      [["Z"], 42.0],
      [["a", "b", 0], 40],
      [["a", "b", 1], 2]
    ]
    assert{ expected == pairs.sort }
  end
  testing 'converting data with numeric keys into a list' do
    data = Hashish.data(:list)
    assert{
      data.set(
        0 => 40,
        1 => 2
      )
    }
    assert{ data.to_array == [40,2] }
  end


# parser
#
  testing 'parsing a simple hash by key' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2
    }
    parsed = Hashish.parse(:key, params)
    expected = {'a' => 40, 'b' => 2}
    assert{ parsed =~ expected }
  end
  testing 'parsing a nested hash by key' do
    params = {
      'key(a,x)' => 40,
      'key(a,y)' => 2
    }
    parsed = Hashish.parse(:key, params)
    expected = {'a' => {'x' => 40, 'y' => 2}} 
    assert{ parsed =~ expected }
  end
  testing 'parsing a deeply nested hash by key' do
    params = {
      'key(a,b,x)' => 40,
      'key(a,b,y)' => 2
    }
    parsed = Hashish.parse(:key, params)
    expected = {'a' => {'b' => {'x' => 40, 'y' => 2}}} 
    assert{ parsed =~ expected }
  end

end









BEGIN {
  require 'test/unit'
  STDOUT.sync = true
  $:.unshift 'lib'
  $:.unshift '../lib'
  $:.unshift '.'

  def Testing(*args, &block)
    Class.new(Test::Unit::TestCase) do
      def self.slug_for(*args)
        string = args.flatten.compact.join('-')
        words = string.to_s.scan(%r/\w+/)
        words.map!{|word| word.gsub %r/[^0-9a-zA-Z_-]/, ''}
        words.delete_if{|word| word.nil? or word.strip.empty?}
        words.join('-').downcase
      end

      @@testing_subclass_count = 0 unless defined?(@@testing_subclass_count) 
      @@testing_subclass_count += 1
      slug = slug_for(*args).gsub(%r/-/,'_')
      name = ['TESTING', '%03d' % @@testing_subclass_count, slug].delete_if{|part| part.empty?}.join('_')
      name = name.upcase!
      const_set(:Name, name)
      def self.name() const_get(:Name) end

      def self.testno()
        '%05d' % (@testno ||= 0)
      ensure
        @testno += 1
      end

      def self.testing(*args, &block)
        method = ["test", testno, slug_for(*args)].delete_if{|part| part.empty?}.join('_')
        define_method("test_#{ testno }_#{ slug_for(*args) }", &block)
      end

      alias_method '__assert__', 'assert'

      def assert(*args, &block)
        if block
          label = "assert(#{ args.join(' ') })"
          result = nil
          assert_nothing_raised{ result = block.call }
          __assert__(result, label)
          result
        else
          result = args.shift
          label = "assert(#{ args.join(' ') })"
          __assert__(result, label)
          result
        end
      end

      def subclass_of exception
        class << exception
          def ==(other) super or self > other end
        end
        exception
      end

      module_eval &block
      self
    end
  end
}
