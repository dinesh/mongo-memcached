

class User 
  include Mongoid::Document
  field :name
  field :username
  field :age, :type => Integer
  field :admin, :type => Boolean
  references_many :categories, :foreign_key => :owner_id, :dependent => :destroy, :autosave => true
  acts_as_memcached :name, :username, :contacts
  
  def contacts
    User.all.collect(&:id)
  end
    
  def man 
    'dinesh'
  end
    
  index_on :_id, :ttl => 1.hour 
  index_on [:_id, :admin] , :ttl => 1.day
  index_on :username
       
end



class Category
  include Mongoid::Document
  field :system_type
  field :name
  referenced_in :owner, :class_name => 'User'
  field :location_id, :type => Integer
  
  acts_as_memcached
    index_on :_id
    index_on :owner_id
    index_on [:owner_id, :system_type ]
    index_on [:system_type]
    index_on [:system_type, :location_id]
   
end



module DB
  def self.clear
    User.delete_all
    Category.delete_all
  end
end

