# built-in libs
#
  require 'enumerator'
  require 'pathname'

# rubygem libs
#
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  require 'tagz'
  #require 'orderedhash'
  require 'json'

# hashish libs
#
  module Hashish
    ::H = Hashish unless defined?(::H)
    Version = '0.4.2' unless defined?(Version)

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
    load 'exceptions.rb'
    load 'support.rb'
    load 'status.rb'
    load 'hash_with_indifferent_access.rb'
    load 'hash_methods.rb'
    load 'data.rb'
    load 'data/form.rb'
    load 'errors.rb'
    load 'slug.rb'
    load 'parameter_parser.rb'
    load 'api.rb'
  end
