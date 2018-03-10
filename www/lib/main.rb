# encoding: UTF-8

# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
require "unicode_utils"
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader




  get('/') do
    user=session[:user]
    logger.info env["rack.session.options"]
    game=user.team.nil? ? nil :  Game[user.team.active_game]
    logger.info game
    if user.team_adopt && !game.nil?
      case game.state(user)
      when :wait
        res=  DB[:games].left_join(:teams,:id=>:team_id).where(:games__id=>game.id).select(:games__id,:games__title,:games__anounce,:games__start,:games__stop).first
        tms=DB[:game_reg].join(:teams,:id=>:team_id).where(:game_id=>game.id).select(:title,:adopt).all
        autors=DB[:gameowner].join(:users,:id=>:user_id).left_join(:teams,:users__team_id=>:teams__id).where(:gameowner__game_id=>game.id).
        select(Sequel.as(:teams__title, :team), Sequel.as(:users__title, :title)).all
        res[:autors]=autors.map { |e| e[:team].nil? ? "#{e[:title]}" : "#{e[:title]} [#{e[:team]}]" }.join(', ')
        erb :index_game_wait,:locals=>{:game=>res,:tms=>tms}
      when :ingame
        if user.team.curent_levels.empty?
          erb   :index_nolevels,:locals=>{:game=>game}
        else
          # logger.info request
          etag "index_game" , :weak
          cache_control :private, :must_revalidate, :max_age => 3600
          return 304 if request["HTTP_IF_NONE_MATCH"]=='W/"index_game"'
          erb :index_game
        end
      when :intest,:ingame
        if user.team.curent_levels.empty?
          erb   :index_nolevels,:locals=>{:game=>game}
        else
          # logger.info request
          etag "index_game" , :weak
          cache_control :private, :must_revalidate, :max_age => 3600
          return 304 if request["HTTP_IF_NONE_MATCH"]=='W/"index_game"'
          erb :index_game
        end


      when :start
        game.start_game(user)
        erb :index_game
      when :closed
        erb :index_game_close,:locals=>{:game=>game}
      when :finish
        erb :index_game_finish
      when :end
        erb :index_game_end, :locals=>{:game=>game}
      else
        logger.info ('else')
        erb :games
      end
      # if  (game.run? || game.team_id==user.team_id )
      #   logger.info game.state(user.team)
      #   erb :index_game
      # else
      #   logger.info game.state(user.team)
      #   erb :index_game
      # end
    else
      #logger.info game.state(user.team)

      erb :games
    end

  end
  get('/test/start/:id'){
    begin
      id=params["id"]
      user=session[:user]
      game=Game[id]
      halt 'game not found' if game.nil?
      halt 'game closed' if game.closed
      halt 'только для админов или авторов' if !game.owner?(user)
      if user.team.active_game==game.id
        DB[:status].where(:team_id=>user.team_id,:game_id=>game.id).delete()
        DB[:gamelog].where(:team_id=>user.team_id,:game_id=>game.id).delete()
        game.start_game(user)
        logger.info 'Тест запущен'
        redirect '/', 'Тест запущен'
      else
        logger.info('Нет доступа')
        redirect '/', 'Нет доступа'
      end
    rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  get('/test/reset/:id'){
    begin
      id=params["id"]
      user=session[:user]
      game=Game[id]
      halt 'game not found' if game.nil?
      halt 'только для админов или авторов' if !game.owner?(user)
      if  user.team.active_game==game.id
        DB[:status].where(:team_id=>user.team_id,:game_id=>game.id).delete()
        DB[:gamelog].where(:team_id=>user.team_id,:game_id=>game.id).delete()
        # game.start_game(user.team)
        logger.info 'Тест обнулен'
        redirect '/', 'Тест обнулен'
      else
        logger.info('Нет доступа')
        redirect '/', 'Нет доступа'
      end
    rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  post('/g/log'){
    begin
      user=session[:user]
      return { total: 1, rows: [{:id=>0,:ts=>Time.now.to_f*1000,:msg=>'нет доступа'}] }.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      logger.info game
      game.process_state(user)
      limit=params["rows"].nil? ? 20 : params["rows"].to_i
      offset=params["page"].nil? ? 0 : (params["page"].to_i-1)*limit
      cnt=DB[:gamelog].where(:game_id=>game.id,:team_id=>user.team_id).count
      resp=DB[:gamelog].where(:game_id=>game.id,:team_id=>user.team_id).reverse(:ts,:id).limit(limit,offset).all
      resp.map!{ |e|
        r={}
        r[:id]=e[:id]
        r[:valid]=e[:valid]
        r[:msg]=e[:input].to_s+e[:msg].to_s
        r[:ts]=e[:ts].strftime("%H:%M:%S<font size='1'>.%L</font>")
        r[:user]=e[:user_id].nil? ? 'Система' :User[e[:user_id]].title
        r[:act]=e[:action]
        r
      }
      return {total:cnt,rows:resp}.to_json

    rescue Exception => e
      logger.error e
      { total: 1, rows: [{:id=>0,:ts=>Time.now.to_f*1000,:msg=>e.message}] }.to_json
    end
  }
  get('/g/levels'){
    begin
      user=session[:user]
      return { state: false, message: "нет доступа"}.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      logger.info game
      game.process_state(user)
      resp=user.team.curent_levels.map { |e|
        r={}
        r[:id]=e.level_id
        r[:title]=e.level.hide_title ? "Уровень № #{e.level.number}" : "(№#{e.level.number}) #{e.level.title}"
        # r[:server_time]=Time.now
        r[:timeout]= e.level.type=='infinite' || e.level.type=='infinite_olympic' ? (Time.now+60*60*24).to_f*1000 : (e.enter+e.level.duration).to_f*1000 
        r
      }
      return {state:true, data:resp,:server_time=>Time.now.to_f*1000}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/g/level/info/:id'){
    begin
      user=session[:user]
      level_id=params["id"]
      return { state: false, message: "нет доступа"}.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      game.process_state(user)

      level_status=user.team.get_level(level_id)
      return { state: false, message: "нет доступа e->l.s.n?"}.to_json  if level_status.nil?
      logger.info level_status
      resp={}
      resp[:id]=level_status.level_id
      resp[:duration]=level_status.level.duration
      resp[:question]=level_status.level.question
      resp[:answer]=level_status.level.answer.join(',') if !level_status.spoiler.nil?
      resp[:spoiler]=level_status.level.spoiler if !level_status.spoiler.nil?
      resp[:title]=level_status.level.hide_title ? "Уровень № #{level_status.level.number}" : "(№#{level_status.level.number}) #{level_status.level.title}"
      #TODO codes stat?
      return {state:true, data:resp}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/g/level/codes/:id'){
    begin
      user=session[:user]
      level_id=params["id"]
      return { state: false, message: "нет доступа"}.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      game.process_state(user)

      level_status=user.team.get_level(level_id)
      return { state: false, message: "нет доступа e->l.s.n?"}.to_json  if level_status.nil?
      logger.info level_status


      resp=level_status.codes_list.map { |e|
        r={}
        r[:id]=e[:id]
        r[:title]=e[:title]
        r[:number]=e[:number]
        r[:sektor]=e[:sektor]
        r[:ko]=e[:ko]
        r[:bonus]=e[:bonus]
        r[:main]=e[:main]
        r[:hint]=e[:hint] if !e[:valid].nil? || (level_status.level.code_hint_timer >0 && level_status.enter+level_status.level.code_hint_timer<=Time.now)
        r[:note]=e[:note] if !e[:valid].nil?
        r[:code]=e[:code].join(',') if !e[:valid].nil?
        r[:user]=e[:user].title if !e[:valid].nil?
        r[:ts]=e[:ts].strftime("%H:%M:%S<font size='1'>.%L</font>") if !e[:valid].nil?
        r
        # e
      }
      if level_status.level.type=='fallout'
        resp=resp.select { |e| 
          e[:main] || e.key?(:user)
         }
      end
      r={state:true, data:resp,stat:level_status.codes_stat}
      r[:olympic]=true if level_status.level.type=='olympic' or level_status.level.type=='olympic_bonus' or level_status.level.type=='infinite_olympic'
      r[:hint_timer]=(level_status.enter+level_status.level.code_hint_timer).to_f*1000 if (level_status.level.code_hint_timer >0 && level_status.enter+level_status.level.code_hint_timer>Time.now)

      return r.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/g/level/hints/:id'){
    begin
      user=session[:user]
      level_id=params["id"]
      return { state: false, message: "нет доступа"}.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      game.process_state(user)

      level_status=user.team.get_level(level_id)
      return { state: false, message: "нет доступа e->l.s.n?"}.to_json  if level_status.nil?
      logger.info level_status


      resp=DB[:hints].where(:level_id=>level_status.level_id).order(:timer).map { |e|
        r={}
        r[:id]=e[:id]
        r[:title]=e[:title]
        r[:timer]=e[:timer]
        r[:timeout]=(level_status.enter+e[:timer]).to_f*1000
        r[:text]=e[:text] if level_status.enter+e[:timer]<=Time.now
        r
      }



      return {state:true, data:resp}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  post('/g/input'){
    begin
      ts=Time.now
      user=session[:user]
      level_id=params["level"]
      return { state: false, message: "нет доступа"}.to_json  if !user.game_play?
      game= Game[user.team.active_game]
      game.process_state(user,ts)

      level_status=user.team.get_level(level_id)
      return { state: false, message: "нет доступа e->l.s.n?"}.to_json  if level_status.nil?
      logger.info level_status
      data= UnicodeUtils.downcase(params["data"].to_s).strip.gsub(/\s/,'')
      logger.info (data)
      resp=level_status.process_input(data,user,ts)
      logger.info resp
      r={}
      r[:type]=resp[:type]
      r[:valid]=resp[:state]
      r[:number]=resp[:code][:number] if !resp[:code].nil?
      r[:sektor]=resp[:code][:sektor] if !resp[:code].nil?
      r[:bonus]=resp[:code][:bonus] if !resp[:code].nil?
      r[:title]=resp[:code][:title] if !resp[:code].nil?
      r[:main]=resp[:code][:main] if !resp[:code].nil?
      r[:ko]=resp[:code][:ko] if !resp[:code].nil?




      r[:id]=resp[:code][:id] if !resp[:code].nil?
      r[:hint]=resp[:code][:hint] if !resp[:code].nil?
      r[:note]=resp[:code][:note] if !resp[:code].nil?
      r[:code]=resp[:code][:code].join(',') if !resp[:code].nil?
      r[:ts]= resp[:log].nil? ?  resp[:ts].strftime("%H:%M:%S<font size='1'>.%L</font>") : resp[:log][:ts].strftime("%H:%M:%S<font size='1'>.%L</font>")
      # r[:ts]=resp[:log][:ts].to_i if !resp[:log].nil?
      r[:user]=resp[:log].nil? ? user.title : User[resp[:log][:user_id]].title
      r[:input]=data
      game.process_state(user,ts)

      # r[:code_stat]=level_status.codes_stat()
      return {state:true, data:r,stat:level_status.codes_stat}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }


end
