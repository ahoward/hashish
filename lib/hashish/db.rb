module Hashish
  class Db
    attr_accessor :path

    def initialize(*args)
      options = Hashish.hash(args.last.is_a?(Hash) ? args.pop : {})
      @path = (args.shift || options[:path] || 'hashish.yml').to_s
      FileUtils.mkdir_p(File.dirname(@path)) rescue nil
    end

    def db
      self
    end

    def ystore
      @ystore ||= YAML::Store.new(path)
    end

    class Collection
      def initialize(name, db)
        @name = name.to_s
        @db = db
      end

      def save(data = {})
        @db.save(@name, data)
      end
      alias_method :create, :save
      alias_method :update, :save

      def find(id = :all)
        @db.find(@name, id)
      end

      def all
        find(:all)
      end

      def [](id)
        find(id)
      end

      def delete(id)
        @db.delete(@name, id)
      end

      def to_hash
        transaction{|y| y[@name]}
      end

      def to_yaml(*args, &block)
        Hash.new.update(to_hash).to_yaml(*args, &block)
      end

      def transaction(*args, &block)
        @db.ystore.transaction(*args, &block)
      end
    end

    def [](name)
      Collection.new(name, db)
    end

    def transaction(*args, &block)
      ystore.transaction(*args, &block)
    end

    def save(collection, data = {})
      data = Hashish.data(data)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        id = next_id_for(collection, data)
        collection[id] = data
      end
    end

    alias_method :create, :save
    alias_method :update, :save

    def find(collection, id = :all)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        if id.nil? or id == :all
          collection.values.map{|data| Hashish.data(data)}
        else
          Hashish.data(collection[String(id)])
        end
      end
    end

    def delete(collection, id = :all)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        if id.nil? or id == :all
          collection.clear()
        else
          deleted = collection.delete(String(id))
          Hashish.data(deleted) if deleted
        end
      end
    end

    def next_id_for(collection, data)
      begin
        id = id_for(data)
        raise if id.strip.empty?
        id
      rescue
        data['id'] = String(collection.size + 1)
        id_for(data)
      end
    end

    def id_for(data)
      String(data[:_id] || data['_id'] || data[:id] || data['id'] || data.id)
    rescue
      raise "no id discoverable for #{ data.inspect }"
    end

    def to_hash
      ystore.transaction do |y|
        y.roots.inject(Hash.new){|h,k| h.update(k => y[k])}
      end
    end

    def to_yaml(*args, &block)
      to_hash.to_yaml(*args, &block)
    end

    class << Db
      attr_accessor :root
      attr_accessor :instance

      def default_root()
        defined?(Rails.root) ? File.join(Rails.root.to_s, 'db') : './db'
      end

      def default_path()
        File.join(default_root, 'hashish.yml')
      end

      def method_missing(method, *args, &block)
        super unless instance.respond_to?(method)
        instance.send(method, *args, &block)
      end
    end

    Db.root = Db.default_root
    Db.instance = Db.new(Db.default_path)
  end

  def Hashish.db(*args, &block)
    if args.empty? and block.nil?
      Db.instance
    else
      method = args.shift
      Db.instance.send(method, *args, &block)
    end
  end
end
