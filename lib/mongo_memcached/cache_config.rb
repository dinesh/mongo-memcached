

module MongoMemcached

  class CacheConfig
    attr_accessor :fields
    
    def initialize _fields = []
        @fields = Array(_fields).sort
    end
    
    def hot_fields
      @fields
    end
    
  end
  
  class CachedDocument   
    attr_accessor :attributes, :klass, :id, :parent
    
    def initialize attrs = {}
      @attributes = attrs
    end
    
    def _load_parent
      @parent || (@parent = load_parent)
    end
    
    def method_missing sym, *args, &block
      begin 
        if attributes.has_key?(sym) 
          attributes[sym] 
        else
          args.size > 0 ? _load_parent.send(sym, args, &block) :  _load_parent.send(sym)
        end  
      rescue Exception => e
        puts e.message
        pp e.backtrace
        super 
      end
    end
    
    def load_parent    
        if index = klass.primary_index
          key = index.cache_key('_id', id)
          _, primary_object, hit = index.get_key_and_value_at_index(['_id', id], { :primary => true } )
          primary_object
        end
    end
    
  end
end