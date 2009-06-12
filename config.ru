require 'rubygems'
require 'sinatra.rb'

root_dir = File.dirname(__FILE__)

set :environment, (ENV['RACK_ENV'] || 'production').to_sym
set :root,        root_dir
disable :run
require File.join(root_dir, 'webserver.rb')

run Sinatra::Application
