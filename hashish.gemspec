## hashish.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "hashish"
  spec.version = "1.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "hashish"
  spec.description = "description: hashish kicks the ass"

  spec.files = ["a.rb", "db", "hashish.gemspec", "lib", "lib/hashish", "lib/hashish/active_record.rb", "lib/hashish/api", "lib/hashish/api/dsl.rb", "lib/hashish/api/endpoint.rb", "lib/hashish/api/mode.rb", "lib/hashish/api.rb", "lib/hashish/blankslate.rb", "lib/hashish/data.rb", "lib/hashish/db.rb", "lib/hashish/errors.rb", "lib/hashish/exceptions.rb", "lib/hashish/form.rb", "lib/hashish/hash_methods.rb", "lib/hashish/hash_with_indifferent_access.rb", "lib/hashish/mongo_mapper.rb", "lib/hashish/options.rb", "lib/hashish/params.rb", "lib/hashish/rails.rb", "lib/hashish/slug.rb", "lib/hashish/status.rb", "lib/hashish/support.rb", "lib/hashish/util.rb", "lib/hashish/validations.rb", "lib/hashish.rb", "Rakefile", "README", "test", "test/db", "test/hashish.rb", "test/testing.rb", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true
  spec.test_files = "test/hashish.rb"

  ### spec.add_dependency 'lib', '>= version'
  spec.add_dependency 'tagz'
  spec.add_dependency 'arrayfields'
  spec.add_dependency 'orderedhash'
  spec.add_dependency 'options'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/hashish/tree/master"
end
