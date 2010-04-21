require File.join(File.dirname(__FILE__), 'testing')

require 'hashish'


Testing Hashish do

# data
#
  testing 'basic data can be constructed' do
    data = assert{ Hashish.data.new }
  end
  testing 'basic data can be constructed with a name' do
    data = assert{ Hashish.data.new('name') }
    assert{ data.name == 'name' }
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
  testing "new? on non-id'd data" do
    d = Hashish.data
    assert{ !d.new? }
  end
  testing "new? on id'd data" do
    d = Hashish.data(:id => 42)
    assert{ d.new? }
  end
  testing "blank? on empty data" do
    assert{ Hashish.data.blank? }
  end
  testing "blank? on non-empty, but blank, data" do
    assert{ Hashish.data(:key => nil).blank? }
    assert{ Hashish.data(:key => []).blank? }
    assert{ Hashish.data(:key => {}).blank? }
    assert{ Hashish.data(:key => 0).blank? }
    assert{ Hashish.data(:key => [[nil],[[]]]).blank? }
    assert{ Hashish.data(:key => {:a => nil}).blank? }
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

# schema
#
  testing 'schema with defaults' do
    params = {:n => 42.0}
    schema =
     H(:data,
       {
       :a => {
         :b => 42
       },
       :n => 0
       }
     )

      result = schema.apply(params)
      assert{ result[:n] == 42.0 }
      assert{ result.get(:a,:b) == 42 }
  end
 

# hash_methods.rb
#
  testing 'has? on simple hash' do
    d = Hashish.data(:name, :key => :val)
    assert{ d.has?(:key) }
    assert{ !d.has?(:missing) }
  end

  testing 'has? on nested hash' do
    d = Hashish.data(:name, :key => {:key2 => :val})
    assert{ d.has?(:key, :key2) }
    assert{ !d.has?(:key, :missing) }
  end

  testing 'has? on simple array' do
    d = Hashish.data(:name, :array => [0])
    assert{ d.has?(:array,0) }
    assert{ !d.has?(:array,1) }
  end

  testing 'has? on nested array' do
    d = Hashish.data(:name, :nested => {:array => [0]})
    assert{ d.has?(:nested, :array, 0) }
    assert{ !d.has?(:nested, :array, 1) }
  end



# errors.rb
#
  testing 'that clear does not drop sticky errors' do
    errors = Hashish::Errors.new
    errors.add! 'sticky', 'error'
    errors.add 'not-sticky', 'error'
    errors.clear
    assert{ errors['sticky'].first == 'error' }
    assert{ errors['not-sticky'].nil? }
  end

  testing 'that clear! ***does*** drop sticky errors' do
    errors = Hashish::Errors.new
    errors.add! 'sticky', 'error'
    errors.add 'not-sticky', 'error'
    errors.clear!
    assert{ errors['sticky'].nil? }
    assert{ errors['not-sticky'].nil? }
  end

  testing 'that global errors are sticky' do
    errors = Hashish::Errors.new
    global = Hashish::Errors::Global
    errors.add! 'global-error'
    errors.clear
    assert{ errors[global].first == 'global-error' }
    errors.clear!
    assert{ errors[global].nil? }
  end

# validations
#
  testing 'that simple validations work' do
    data = Hashish.data
    assert{ data.validates(:password){|password| password == 'haxor'} }
    data.set(:password, 'fubar')
    assert{ not data.valid? }
  end

# validating
#
  testing 'that validations can be cleared and do not clobber manually added errors' do
    data = Hashish.data
    assert{ data.validates(:email){|email| email.to_s.split(/@/).size == 2} }
    assert{ data.validates(:password){|password| password == 'haxor'} }

    data.set(:email => 'ara@dojo4.com', :password => 'fubar')
    assert{ not data.valid? }

    data.set(:password => 'haxor')
    assert{ data.valid? }

    data.errors.add(:name, 'ara')
    assert{ not data.valid? }
  end

end
