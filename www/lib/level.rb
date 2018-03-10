# encoding: UTF-8

# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/level/layout/:id') {
    content_type :js

    erb :game
  }
  

end
