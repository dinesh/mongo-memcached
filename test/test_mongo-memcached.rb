require 'helper'
require 'db'

class TestMongoMemcached < Test::Unit::TestCase
  context "Testing memcached connection" do
    setup do
      $config = YAML.load(IO.read(File.join(File.dirname(__FILE__), '/../config/memcache.yml')))['test']
      $cache = Memcached.new( Array($config['servers']) )
      $cache.flush
      DB::clear
    end
    
    should "memcached connection should be according to the given servers" do
      assert_equal($cache.servers.size, $config['servers'].size )
    end
  end
end



