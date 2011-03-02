


class Array
  alias_method :count, :size
  def in_groups_of(number, fill_with = nil)
     padding = (number - size % number) % number
     collection = dup.concat([fill_with] * padding)
     
     if block_given?
       collection.each_slice(number) { |slice| yield(slice) }
     else
       [].tap do |groups|
         collection.each_slice(number) { |group| groups << group }
       end
     end
  end
  
  def to_hash
     keys_and_values_without_nils = in_groups_of(2).reject{|pair| pair[0].nil?  }
     hash = {}
     keys_and_values_without_nils.map{|p1, p2| hash.store(p1, p2) }
     hash
  end
end
