# built-in libs
#
  require 'enumerator'
  require 'fileutils'
  require 'pathname'
  require 'yaml'
  require 'yaml/store'

# rubygem libs
#
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  require 'tagz'
  require 'arrayfields'
  require 'orderedhash'
  require 'options'


# hashish libs
#
  module Hashish
    Version = '1.0.0' unless defined?(Version)

    def version
      Hashish::Version
    end

    def libdir(*args, &block)
      @libdir ||= Pathname.new(__FILE__).realpath.to_s.sub(/\.rb$/,'')
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call()
        ensure
          $LOAD_PATH.shift()
        end
      end
    end

    extend self
  end

  Hashish.libdir do
    load 'blankslate.rb'
    load 'exceptions.rb'
    load 'support.rb'
    load 'status.rb'
    load 'hash_with_indifferent_access.rb'
    load 'hash_methods.rb'
    load 'data.rb'
    load 'form.rb'
    load 'errors.rb'
    load 'validations.rb'
    load 'slug.rb'
    load 'params.rb'
    load 'api/mode.rb'
    load 'api/endpoint.rb'
    load 'api/dsl.rb'
    load 'api.rb'
    load 'rails.rb'
    load 'active_record.rb'
    load 'mongo_mapper.rb'
    load 'db.rb'
  end

  unless defined?(H)
    H = Hashish

    def Hashish(*args, &block)
      Hashish.data(*args, &block)
    end

    def H(*args, &block)
      Hashish.data(*args, &block)
    end
  end
