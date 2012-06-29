$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'

Bundler.require

require 'evented-spec'
require 'eventmachine'
require 'amqp'

require 'log_agent'