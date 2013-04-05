$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'

Bundler.require

require 'evented-spec'
require 'eventmachine'
require 'amqp'
require 'timecop'

require 'log_agent'

Dir[File.expand_path("../support/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |c|

  c.include FixtureLoading

end