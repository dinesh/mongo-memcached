

module Mongoid
  module Document
    include MongoMemcached
    def shallow_clone
      MongoMemcached::CachedDocument.new.tap do |other|
        self.class.hot_fields.each{|name| other.attributes[name] = self.send(name).dup if self.class.hot?(name) }
        other.id = self.id
        other.klass = self.class
      end
    end
     
  end
end



module Mongoid
  module Contexts
    class Mongo
      def attribute_value_pair
        criteria.selector.collect{|key, value| [key.to_s, value.to_s ] }.flatten
      end

      def indexed_on?(keys)
        klass.indices.select{|c| c.attributes.sort == keys.collect(&:to_sym).sort }.first
      end
  
      def cached_execute selector, paginating = false
          cursor = klass.collection.find(selector, process_options)
          if cursor
          @count = cursor.count if paginating
            cursor
          else
            []
          end
      end
      
      protected
  
      def advance_operators 
        ['$all', '$exists', '$mod', '$ne', '$in', '$nin', '$nor', '$or', '$size', '$type', '$elemMatch' ]
      end
  
      def hit_or_miss index
        key = index.cache_key(attribute_value_pair)
        unless ( cached_entries = klass.get(key) )
          _, cached_entries, hit = index.get_key_and_value_at_index(attribute_value_pair)
        end
        cached_entries
      end
      
      def cached_documents index
              key = index.cache_key(attribute_value_pair)
              cached_entries =  hit_or_miss(index)
              selector['_id']  = { "$nin" => cached_entries } if cached_entries 
          
              case cached_entries
                when Array
                  if cached_entries.present?
                    keys = cached_entries.map{|e| index.cache_key(['_id', e]) }
                    cached_entries = klass.get(keys) do |missed_keys|
                                      puts "missed => #{missed_keys.inspect}"
                                      primary_index = indexed_on?('_id')
                                      missed_ids = missed_keys.map{|t| t.split('_id/').last }
                                      klass.where(:_id.in => missed_ids).entries.map do |doc|
                                        key = primary_index.cache_key(['_id', doc.id ])
                                        doc.shallow_clone
                                      end
                                   end
                  end
              
                else
                  cached_entries = { }
              end
              cached_entries
      end    
      
      def caching(&block)
        if defined? @collection
          @collection.each(&block)
        else
          cached_entries = {}
          key = criteria.selector.keys.sort
          if index = indexed_on?(key) and criteria.selector.any?{|k, v| v.class == Hash } == false
              cached_entries = cached_documents(index)
              cached_entries.each do |key, doc|
                puts "\t>> [CACHED] #{key} : #{doc.inspect}"
                yield doc if block_given?
              end
              selector.delete('_id')  
          else
            cached_execute(criteria.selector).each{|doc| yield doc if block_given? }
          end
        
        end
    
      end
  
    end
  end
end