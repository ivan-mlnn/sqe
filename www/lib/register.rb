# encoding: UTF-8
# rubocop:disable Style/StringLiterals
# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/register') do
    erb :register
  end

  post('/register') do
    logger.info params
    content_type :js
    begin
      login=UnicodeUtils.downcase(params['login'].to_s).strip
      pass=UnicodeUtils.downcase(params['password'].to_s).strip
      if login.empty? || pass.empty?
        return { state: false, message: "Логин или пароль не может быть пустым" }.to_json

      end
      if  User[login: login].nil?
        User.new(login:login, password: pass).save
        { state: true }.to_json
      else
        { state: false, message: "Логин занят" }.to_json
      end
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end

  end
end
