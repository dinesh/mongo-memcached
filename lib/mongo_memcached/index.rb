

module MongoMemcached
  class Index
      attr_accessor :collection, :attributes, :options, :membase
      
      def initialize collection, attributes, opts = { :limit => 1000 }
        @collection, @attributes, @options = collection, Array(attributes), opts.update(opts)
      end   
      
      def repository
        collection.membase
      end
      
      def attribute_value_pairs object
        attributes.inject([]){|pairs, field|  pairs << [ field, object.attributes[field] ]  }.flatten
      end
      
      def add_objects_to_cache pairs, objects, options = {}
        if primary_key?
          add_object_to_primary_key_cache(pairs, objects, options)
        else
          add_to_index(pairs, objects, options)
        end
      end
      
      def add_object_to_primary_key_cache pairs, object, options = {}
        repository.set(key = cache_key(pairs), serialize_objects(object) )
        repository.set(key = primary_cache_key(pairs), object )
      end
      
      def add_to_index pairs, object, options = {}
        order = options[:order] || :asc
        key = cache_key(pairs)
        _, cache_value, hit = get_key_and_value_at_index(pairs)
        if hit
          object_to_add = serialize_objects(object)
          objects = (cache_value + [object_to_add]).sort do |a, b|
            (a <=> b) * (order == :asc ? 1 : -1)
          end.uniq
          collection.set(key, objects)
        end
      end
      
      def remove_from_index pairs, objects, options = {}
        primary_key? ? remove_from_primary_key_index(pairs, objects, options) : remove_from_other_index(pairs, objects, options) 
      end
      
      def remove_from_primary_key_index pairs, object, options = {}
        key = cache_key(pairs)
        repository.set(key, [])
      end
      
      def remove_from_other_index pairs, objects, options = {}
        key, cache_value, _ = get_key_and_value_at_index(pairs)
      end
      
      def stalled? objects
        objects = Array(objects)
        objects.any?{|o| attributes.any?{|option| o.changes.has_key?(option.to_s) } }
      end
        
      def update_in_index pairs, objects, options = {}
        if stalled?(objects)
          primary_key? ? update_in_primary_key_index(pairs, objects, options) : update_in_other_index(pairs, objects, options) 
        end
      end
      
      def update_in_primary_key_index pairs, object, options = {}
        key = cache_key(pairs)
        repository.set(key, serialize_objects(object))
      end
      
      def update_in_other_index pairs, objects, options = {}
        key, cache_value, _ = get_key_and_value_at_index(pairs)
      end
      
      
      def serialize_objects objects
          objects = objects.collect{|doc|  primary_key? ? doc.shallow_clone : doc._id }
          primary_key? ? objects.first : objects
      end
      
      def append_objects key, pre_value, new_value, owerite = false
        primary_key? ? new_value : (  pre_value + new_value ).uniq
      end
      
      def primary_key?
        attributes.size == 1 and attributes.first == :_id
      end
      
      def cache_key key, primary = false
        key = key.class == Array ? key.join('/') : key
        collection.cache_key( key, primary )
      end
      
      def get_key_and_value_at_index pairs, options = {}
        key, cache_hit = cache_key(pairs, options[:primary]), true
        cache_value = collection.get(key, options) do 
          cache_hit = false
          objects = collection.where(pairs.to_hash).entries
          options[:primary] && primary_key? ? objects.first : serialize_objects( objects )
        end
        [key, cache_value, cache_hit] 
      end
      
    module Commands
       def add(object)
          clone, pairs = object, attribute_value_pairs(object)
          add_to_index(pairs, [clone], { :overwite =>  true } )
        end

        def update(object)
          clone = object
          update_in_index(attribute_value_pairs(object), [clone])
        end

        def remove(object)
          remove_from_index(attribute_value_pairs(object), object)
        end

        def delete(object)
          key = cache_key(attribute_value_pairs(object))
          expire(key)
        end
   end
   include Commands
    
  end
  
end