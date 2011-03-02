

require 'helper'
require 'db'
require 'pp'

User.delete_all 
Category.delete_all

types = ['hotel', 'nightlife', 'restaurant']

2.times do |i|
  u = User.new(:name => "user_#{i}", :username => "username_#{i}", :admin => i%2, :age => i*10 )
  1.times do |j|
    u.categories.build(:name => 'cat_' + j.to_s , :system_type => types[j%3], :location_id => j % 20)
  end
  pp u
  u.save
end

u = User.where(:username => 'username_0').memcached

u.each do |user|
  puts user.man
  puts user.age
end

