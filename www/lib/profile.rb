# encoding: UTF-8
# rubocop:disable Style/StringLiterals
# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
require "unicode_utils"
require 'digest'
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/profile') do
    title=session[:user].title
    u=session[:user]
    tgtoken=Digest::MD5.hexdigest "#{u.id}-+-#{u.title}^42%#{u.password}~``#{u.login}@`" 
    erb :profile, :locals => {:title => title, :tgusertoken=>"#{u.id}_#{tgtoken}"}
  end

  post('/user/change_password') do
    logger.info params
    content_type :js
    begin
      user=session[:user]
      if params["pass1"].strip != params["pass2"].strip
        { state: false, message: "Пароли не совпадают" }.to_json
      elsif  user.nil?

        { state: false, message:"Надо залогинится еще раз" }.to_json
      else
        if  params["pass1"].strip !=user.password && params["pass1"].strip!=''
          user.password=UnicodeUtils.downcase(params['pass1'].to_s).strip
        end

        if params["title"].strip !=user.title && params["title"].strip!=''
          user.title=params["title"].strip
        end
        if params["theme"].strip !=user.theme && params["theme"].strip!=''
          user.theme=params["theme"].strip
        end
        user.save
        { state: true, message: "Сохранено" }.to_json
      end
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end

  end
end
