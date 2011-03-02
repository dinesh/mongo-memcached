require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
  Bundler.require(:default)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'
require 'shoulda'
require 'redgreen'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongo-memcached'

class Test::Unit::TestCase
end

