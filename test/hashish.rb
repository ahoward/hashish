testdir = File.dirname(File.expand_path(__FILE__))
rootdir = File.dirname(testdir)
libdir = File.join(rootdir, 'lib')

require File.join(testdir, 'testing')
require File.join(libdir, 'hashish')


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

# status
#
  testing 'Status.for' do
    assert{ Hashish::Status.for(:unauthorized).code == 401 }
    assert{ Hashish::Status.for(:UNAUTHORIZED).code == 401 }
    assert{ Hashish::Status.for('unauthorized').code == 401 }
    assert{ Hashish::Status.for('UNAUTHORIZED').code == 401 }
    assert{ Hashish::Status.for('Unauthorized').code == 401 }
    assert{ Hashish::Status.for(:Unauthorized).code == 401 }
    assert{ Hashish::Status.for(:No_Content).code == 204 }
    assert{ Hashish::Status.for(:no_content).code == 204 }
  end

  testing 'that setting status alters errors automatically' do
    d = Hashish.data
    assert{ d.status :unauthorized }
    assert{ not d.errors.empty? }
    assert{ d.errors.to_html.index(d.status) }
    assert{ d.errors.status :ok }
    assert{ d.errors.empty? }
  end

  testing 'status equality operator' do
    s = Hashish::Status.for(401)
    assert{ s == :unauthorized }
    assert{ s == 401 }
    assert{ s != Array.new }
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

# apply
#
  testing 'apply' do
    h = H.data(
      :a => 'default',
      :b => { :x => 'default', :y => 'default' },
      :c => %w[ default default default ]
    )

    params = H.data
    params.set(:a, 'updated')
    params.set(:b, :x, 'updated')
    params.set(:c, 2, 'updated')

    result = h.apply(params)

    assert{ result[:a] == 'updated' }
    assert{ result.get(:b,:x) == 'updated' }
    assert{ result.get(:b,:y) == 'default' }
    assert{ result.get(:c,0) == 'default' }
    assert{ result.get(:c,1) == 'default' }
    assert{ result.get(:c,2) == 'updated' }
  end

  testing 'that apply uses a blacklist' do
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

  testing 'that setting status alters errors object automatically' do
    errors = Hashish::Errors.new
    status = nil
    assert{ status = errors.status :unauthorized }
    assert{ not errors.empty? }
    assert{ errors.to_html.index(status) }
    assert{ status = errors.status :ok }
    assert{ errors.empty? }
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

# cloning
#
  testing 'simple cloning' do
    data = Hashish.data(:foo)
    clone = assert{ data.clone }
    assert{ data.name == clone.name }
    assert{ data.errors == clone.errors }
    assert{ data.errors.object_id != clone.errors.object_id }
    assert{ data.validations == clone.validations }
    assert{ data.validations.object_id != clone.validations.object_id }
    assert{ data.form == clone.form }
    assert{ data.form.object_id != clone.form.object_id }
    assert{ data.status == clone.status }
    assert{ data.status.object_id != clone.status.object_id }
    assert{ data == clone }
  end

# api
#
  testing 'that the api dsl allows endpoint definition' do
    api_class = assert{ Class.new(Hashish.api) }
    assert{
      api_class.class_eval{ endpoint(:foo){} }
    }
    api = nil
    assert{ api = api_class.new }
    assert{ api.respond_to?(:foo) }
    assert{ api.call(:foo) }
  end
  testing 'that endpoints are called according to arity' do
    api = assert{ Class.new(Hashish.api) }
    assert{ api.class_eval{ endpoint(:zero){|| result.update :args => [] } } }
    assert{ api.class_eval{ endpoint(:one){|a| result.update :args => [a]} } }
    assert{ api.class_eval{ endpoint(:two){|a,b| result.update :args => [a,b]} } }

    assert{ api.new.call(:zero).args.size == 0 }
    assert{ api.new.call(:one).args.size == 1 }
    assert{ api.new.call(:two).args.size == 2 }
  end
  testing 'that endpoints have magic params and result objects' do
    api = assert{ Class.new(Hashish.api) }
    assert{ api.class_eval{ endpoint(:foo){ params; result; } } }
    assert{ api.new.call(:foo) }
  end

  testing 'that methods with requirements can be defined' do
    api = assert{ Class.new(Hashish.api) }
    assert{ api.class_eval{ endpoint('/foo/:foo/bar/:bar/:baz'){ result.update(params) } } }
    result = assert{ api.new.call('/foo/42/bar/42.0/forty-two') }
    assert{ result[:foo] = '42' }
    assert{ result[:bar] = '42.0' }
    assert{ result[:baz] = 'forty-two' }
  end


end
