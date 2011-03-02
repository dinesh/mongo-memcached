
module MongoMemcached
  
  module Membase
      def self.included base 
        class << base
            attr_accessor :repository
            delegate :repository, :to => "self.class"
        end
      end
    
      def fetch(keys, options = {}, &block)
        case keys
        when Array
          keys = keys.collect { |key| cache_key(key) }
          hits = repository.get(keys)
          if (missed_keys = keys - hits.keys).any?
            missed_values = block.call(missed_keys)
            hits.merge!( missed_keys.zip( Array(missed_values) ).flatten.to_hash )
          end
          hits
        else
          begin
            value = repository.get(keys)
          rescue
            options[:owerite] = true
          end
          repository.set(keys, new_value = options[:raw] || ( block ? block.call : nil ) ) if options[:owerite] or value.nil?
          v = new_value || value
          puts "\tGET: #{keys} : #{v.inspect}\n"
          v
        end
      end

      
      def get(keys, options = {}, &block)
        case keys
        when Array
          fetch(keys, options, &block)
        else
          fetch(keys, options) do
            if block_given?
              set(keys, result = yield(keys), options)
              result
            end
          end
        end
      end

      def add(key, value, options = {})
        if repository.add(cache_key(key), value, options[:ttl] || 0, options[:raw]) == "NOT_STORED\r\n"
          yield
        end
      end

      def set(key, value, options = {})
        key = cache_key(key, options[:primary])
        puts "\tSET:#{key.inspect} ==> #{value.inspect}\n"
        repository.set(key, value, options[:ttl] || 0)
      end

      def incr(key, delta = 1, ttl = 0)
        repository.incr(cache_key = cache_key(key), delta) || begin
          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.incr(cache_key) }
          result
        end
      end

      def decr(key, delta = 1, ttl = 0)
        repository.decr(cache_key = cache_key(key), delta) || begin
          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.decr(cache_key) }
          result
        end
      end

      def expire(key)
        puts "memcache delete: #{key}"
        repository.delete(cache_key(key))
      end
  
  end
  
end