# encoding: UTF-8

# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
require "unicode_utils"
require 'xxhash'
include Model
# GAME_FILES_PATH='/opt/'
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/arhive/list') {

    erb :arhive_list
  }
  
  get('/arhive/files/:id'){|id|
  begin
    user=session[:user]
    game=Game[id.to_i]
    halt 'только закрытые игры' if !game.closed
    lst=DB[:files].where(:game_id=>game.id).order(:name).all
    erb :arhive_files,:layout=>false , :locals=>{:files=>lst}
  rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  get('/arhive/level/codes_list_ko/:game_id'){|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
      halt 'только закрытые игры' if !game.closed
    
      ko=DB['SELECT DISTINCT ko from codes JOIN levels ON codes.level_id=levels.id WHERE levels.game_id=?',game.id].all
      ko<<{ko:'х.з.'}
      return ko.uniq.to_json
    rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  get('/arhive/game/list/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
      halt 'только закрытые игры' if !game.closed
    

    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :arhive_desktop,:layout=>false , :locals=>{:game_id=>game.id}
  }
  
  
  get('/arhive/game/level/:id') {|id|
    begin
      # redirect if id=="game"
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
      halt 'только закрытые игры' if !game.closed
    
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :arhive_game_level, :locals=>{:level=>level},:layout=>false
  }
  post('/arhive/level/codes_list/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
      halt 'только закрытые игры' if !game.closed
    
      return DB[:codes].where(:level_id=>level.id).order(:number).map{|e|
        e[:code]=e[:code].join(',')
        e[:bonus]=Time.at(e[:bonus]).utc.strftime('%H:%M:%S')
        e[:main]=e[:main] ? 'Осн' : 'Бнс'
        e
      }.to_json
    rescue Exception => e
      logger.error e
      halt e.message
    end
    # erb :admin_game_level_editor, :locals=>{:level=>level},:layout=>false
  }
  
  post('/arhive/level/hints_list/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
      halt 'только закрытые игры' if !game.closed
    
      return DB[:hints].where(:level_id=>level.id).order(:timer).map{|e|
        e[:timer]=Time.at(e[:timer]).utc.strftime('%H:%M:%S')

        e
      }.to_json
    rescue Exception => e
      logger.error e
      halt e.message
    end
    # erb :admin_game_level_editor, :locals=>{:level=>level},:layout=>false
  }
 
  get('/arhive/game/anounce/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
      halt 'только закрытые игры' if !game.closed
    
      autors=DB[:gameowner].where(:game_id=>game.id).map(:user_id)
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :arhive_game_anounce, :locals=>{:game=>game,:autors=>autors},:layout=>false
  }
  get('/arhive/game/level_list/:id') {|id|
    begin
      content_type :js
      user=session[:user]
      game=Game[id.to_i]
      halt 'только закрытые игры' if !game.closed
    
      resp=[]
      resp<<{:link=>"/arhive/game/anounce/#{game.id}",:title=>'Анонс',id:"game_anounce"}
      resp+=DB[:levels].select(:title,:id).where(:game_id=>game.id).order_by(:sequence).map { |e| e[:link]="/arhive/game/level/#{e[:id]}";e }
      return {:state=>true, :list=>resp}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :admin_game_edit, :locals=>{:game_id=>game.id}
  }

  

end
