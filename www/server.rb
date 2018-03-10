require 'sinatra/base'
require 'sinatra/reloader'
require "unicode_utils"
require File.expand_path(File.dirname(__FILE__) + '/lib/main')
require File.expand_path(File.dirname(__FILE__) + '/lib/register')
require File.expand_path(File.dirname(__FILE__) + '/lib/profile')
require File.expand_path(File.dirname(__FILE__) + '/lib/team')
require File.expand_path(File.dirname(__FILE__) + '/lib/game')
require File.expand_path(File.dirname(__FILE__) + '/lib/admin')
require File.expand_path(File.dirname(__FILE__) + '/lib/arhive')
require File.expand_path(File.dirname(__FILE__) + '/lib/stat')
class LoginScreen < Sinatra::Base
  # enable :sessions
  use Rack::Session::Pool, :expire_after =>  2592000 ,:secret=>'42'

  enable :logging
  set :protection, except: [:path_traversal, :session_hijacking,:http_origin]
  include Model
 
  get('/login') { erb :login, layout: false }

  post('/login') do
    logger.info params
    content_type :js
    begin
      login=UnicodeUtils.downcase(params['login'].to_s).strip
      pass=UnicodeUtils.downcase(params['password'].to_s).strip
      user = params.nil? ? nil : User[login: login, password: pass]
      if user.nil?
        
        { success: false, message: "\u041B\u043E\u0433\u0438\u043D/\u041F\u0430\u0440\u043E\u043B\u044C \u043D\u0435\u0432\u0435\u0440\u043D\u044B\u0435" }.to_json
      else
        session[:user] = user
        session[:user_id] = user.id
        { success: true, message: 'OK' }.to_json
      end
    rescue Exception => e
      logger.error e
      { success: false, message: e.message }.to_json
    end
  end
end

class SQE < Sinatra::Base
  # middleware will run before filters
  use LoginScreen
  register Sinatra::Reloader
  set :show_exceptions, false

  before do
    logger.info env["HTTP_X_REAL_IP"]
    logger.info env["HTTP_USER_AGENT"]
    logger.info env["REQUEST_URI"]

    logger.info params
    logger.info session[:user_id]
    logger.info session[:user]

    unless session[:user_id] || request.path_info == '/register' || !request.path_info.match('/game/plain/\d+').nil?
      redirect '/login'

    end
    session[:user]=User[session[:user_id]]
    @theme=session[:user].nil? ? 'default' : session[:user].theme
  end

not_found do
return '
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="ru">
  <head>
    <style type="text/css">
      body {color:#222; font-size:13px;font-family: sans-serif; background:#fff url(/404bg.png) left top repeat-x;}
      h1 {font-size:300%;font-family: Verdana, sans-serif; color:#000}
      #page {font-size:122%;width:720px; margin:144px auto 0 auto;text-align:left;line-height:1.2;}
      #message {padding-right:400px;min-height:360px;background:transparent url(/404.png) right top no-repeat;}
    </style>
    <meta http-equiv="Content-Type" content="application/xhtml; charset=utf-8" />
    <meta name="description" content="Произошла ошибка №404" />
    <title>Error 404 – Page not found</title>
  </head>
  <body>
    <div id="page">
    <div id="message">
      <h1>404</h1>
      <p>— Не то чтобы совсем не попал,— сказал Пух,— но только не попал в шарик!</p>
    </div>
    </div>
  </body>
</html>
'
end

  get('/logout') do
    session[:user_id]=nil
    session[:user]=nil

    erb :logout, :layout=>false
  end
end
