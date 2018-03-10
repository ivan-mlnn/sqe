# encoding: UTF-8

# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/games') {

    erb :games
  }
  get('/game/:id') {|id|
    content_type :js
    user=session[:user]
    res=  DB[:games].left_join(:teams,:id=>:team_id).where(:games__id=>id).select(:games__id,:games__title,:games__anounce,:games__start,:games__stop).first
    tms=DB[:game_reg].join(:teams,:id=>:team_id).where(:game_id=>id).select(:title,:adopt).all
    autors=DB[:gameowner].join(:users,:id=>:user_id).left_join(:teams,:users__team_id=>:teams__id).where(:gameowner__game_id=>id).
    select(Sequel.as(:teams__title, :team), Sequel.as(:users__title, :title)).all
    res[:autors]=autors.map { |e| e[:team].nil? ? "#{e[:title]}" : "#{e[:title]} [#{e[:team]}]" }.join(', ')
    res[:start]=res[:start].to_i
    res[:stop]=res[:stop].to_i
    res[:teams]=tms
    res[:my_team_join]=!DB[:game_reg].where(:game_id=>id,:team_id=>user.team_id).empty?
    res.to_json
  }

  get('/game/plain/:id') {|id|
    # content_type :js
    user=session[:user]
    res=  DB[:games].left_join(:teams,:id=>:team_id).where(:games__id=>id).select(:games__id,:games__title,:games__anounce,:games__start,:games__stop).first
    tms=DB[:game_reg].join(:teams,:id=>:team_id).where(:game_id=>id).select(:title,:adopt).all
    autors=DB[:gameowner].join(:users,:id=>:user_id).left_join(:teams,:users__team_id=>:teams__id).where(:gameowner__game_id=>id).
    select(Sequel.as(:teams__title, :team), Sequel.as(:users__title, :title)).all
    res[:autors]=autors.map { |e| e[:team].nil? ? "#{e[:title]}" : "#{e[:title]} [#{e[:team]}]" }.join(', ')
    res[:start]=res[:start].to_i
    res[:stop]=res[:stop].to_i
    res[:teams]=tms
    res[:duration]=DB[:levels].where(:game_id=>id).sum(:duration)
    res[:no_auth]=user.nil?
    res[:my_team_join]=user.nil? ? false : !DB[:game_reg].where(:game_id=>id,:team_id=>user.team_id).empty?
    logger.info res
    erb :plain_game,:layout=>false , :locals=>{:game=>res}
  }
  

  get('/game/join/:id') {|id|
    begin
      content_type :js
      user=session[:user]
      if !user.captain
        return {state:false,message:'Это должен делать капитан'}.to_json
      end
      if DB[:game_reg].where(:game_id=>id,:team_id=>user.team_id).empty?
        DB[:game_reg].insert(:game_id=>id,:team_id=>user.team_id)
        return {state:true,message:'Заявка подана'}.to_json
      elsif Game[id.to_i].start>Time.now
        DB[:game_reg].where(:game_id=>id,:team_id=>user.team_id).delete
        user.team.active_game=nil
        user.team.save
        return {state:true,message:'Заявка снята'}.to_json
      else
        return {state:true,message:'Заявку нельзя снимать после старта игры'}.to_json
      end
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/game/exit/:id') {|id|
    begin
      user=session[:user]
      if !user.captain
        redirect '/','Это должен делать капитан'
      end
      if Game[id.to_i].stop<Time.now || Game[id.to_i].closed
        user.team.active_game=nil
        user.team.save
      end
      redirect '/'
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/game/start/:id') {|id|
    begin
      user=session[:user]
      if DB[:game_reg].where(:game_id=>id,:team_id=>user.team_id,:adopt=>true).empty?
        # DB[:game_reg].insert(:game_id=>id,:team_id=>user.team_id)
        redirect  '/','Нет одобренной заявки на игру'
      elsif !user.team_adopt
        redirect  '/','ты неактивный член комманды'

      else
        DB[:teams].where(:id=>user.team_id).update(:active_game=>id)
        session[:user]=User[user.id]
        redirect  '/','Вход в игру'
      end
    rescue Exception => e
      logger.error e
      redirect  '/', e.message
    end
  }
  post('/games/list') do

    content_type :js

    res=  DB[:games].where(:closed=>false).select(:id,:title).all
    res.to_json
  end
 post('/old_games/list') do

    content_type :js

    res=  DB[:games].where(:closed=>true).select(:id,:title).order(:id).all
    res.to_json
  end
end
