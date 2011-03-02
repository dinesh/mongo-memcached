require 'mongo_memcached/patches/_array'
require 'mongo_memcached/patches/_symbol'

require 'mongo_memcached/membase'
require 'mongo_memcached/synchronize'
require 'mongo_memcached/index'
require 'mongo_memcached/cache_config'




Mongoid.configure do |config| 
  host = 'localhost'
  config.master = Mongo::Connection.new.db('weigo')
  config.persist_in_safe_mode = false 
end


module MongoMemcached
  extend ActiveSupport::Concern
  
  module ClassMethods  
    def acts_as_memcached *args
      _setup_for_memcached(self)
      self.cache_config = CacheConfig.new( args || self.fields.keys )
    end
    
    def hot_fields
      @cache_config ? @cache_config.hot_fields : []
    end
    
    def hot?(field)
      self.hot_fields.include?(field)
    end
    
    def _setup_for_memcached(base)
      class << base
        attr_accessor :indices, :membase, :cache_config
        include Membase
        alias :repository :membase
      end

      base.class_eval do
        @indices ||= []
        @membase ||= Memcached.new
        include Synchronize
      end

    end 
    
    def memcached?
      respond_to?(:indices)
    end
    
    def memcached
      where().cache
    end
    
    def primary_index
      self.indices.select{|i| i.primary_key? }.first
    end
    
    def index_on attrs, options = { }
      options.assert_valid_keys(:ttl, :order)
      index = Index.new self, attrs, options || {}
      self.indices.unshift( Index.new(self, attrs, options || {}) )
      self.indices.sort_by{|index| index.attributes.size }
    end
    
    def cache_key(key, primary = false)
      key = key.split(':').last
      primary ?   "#{name.downcase}/p:#{key.to_s.gsub(' ', '+')}" : 
                  "#{name.downcase}:#{key.to_s.gsub(' ', '+')}"    
    end
        
  end
  
end

require 'mongo_memcached/patches/_mongoid'
  