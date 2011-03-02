
module MongoMemcached
  
  module Synchronize
    def self.included base
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end
  
    module InstanceMethods
       def self.included(mongo_class)
          mongo_class.class_eval do
            after_create :add_to_caches
            after_update :update_caches
            after_destroy :remove_from_caches
          end
        end
      
        def add_to_caches
          InstanceMethods.unfold(self.class, :add_to_caches, self)
        end

        def update_caches
          InstanceMethods.unfold(self.class, :update_caches, self)
        end

        def remove_from_caches
          return if new_record?
          InstanceMethods.unfold(self.class, :remove_from_caches, self)
        end

        def expire_caches
          InstanceMethods.unfold(self.class, :expire_caches, self)
        end

        private
        def self.unfold(klass, operation, object)
            klass.send(operation, object)
            klass = klass.superclass
        end
    end
  
    module ClassMethods
      def add_to_caches(object)
        indices.each { |index| index.add(object) }
      end

      def update_caches(object)
        indices.each { |index| index.update(object) }
      end

      def remove_from_caches(object)
        indices.each { |index| index.remove(object) }
      end

      def expire_caches(object)
        indices.each { |index| index.delete(object) }
      end
    end
  
  end

end