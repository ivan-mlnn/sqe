# encoding: UTF-8

# require File.expand_path(File.dirname(__FILE__) + '/log/log')

require 'oj'
require 'json'
include Model
class SQE < Sinatra::Base
  register Sinatra::Reloader
 
get('/users_teams/list'){
   content_type :js
    res=DB[:users].left_join(:teams,:id=>:team_id).select(:users__login,:users__id,:users__title, Sequel.as(:teams__title,:team)).order(:teams__title,:users__title,:users__login).map { |e| 
      if e[:team].nil?
        e[:team]='--Отщепенцы--'
      end
      e
     }
    return res.to_json
}

  post('/teams/list') {
    content_type :js
    res=  DB[:teams].all
    res<<{:id=>0,:title=>"Покинуть текущую комманду"}
    res.to_json

  }

  post('/team/members') {
    content_type :js
    if session[:user].team_id.nil?
      return [].to_json
    end
    res=  DB[:users].where(:team_id=>session[:user].team_id).select(:id,:login,:captain,:team_adopt,:title).all
    res.to_json

  }
  post('/team/mng'){
    begin
      user=session[:user]
      usr_edit=User[params["user_id"].to_i]
      if !user.captain
        return {state: false,message:'Ты не капитан чтобы так делать 😜'}.to_json
      end
      if usr_edit.nil?
        return {state: false,message:'Кто тут умный очень?'}.to_json
      end
      if user.team_id != usr_edit.team_id
        return {state: false,message:'Кто тут умный очень? 😜'}.to_json
      end
      if params["captain"].nil? && user.id==usr_edit.id && DB[:users].where(:team_id=>user.team_id,:captain=>false).count==1
        return {state: false,message:'Нельзя снимать с себя капитанство не оставив другого капитана'}.to_json
      end
      if params["adopt"].nil? && user.id==usr_edit.id
        return {state: false,message:'Нельзя снимать с себя активный статус'}.to_json
      end
      if params["adopt"].nil? && (!params["captain"].nil? || usr_edit.captain)
        return {state: false,message:'Нельзя снимать с капитанов активный статус'}.to_json
      end

      usr_edit.captain=!params["captain"].nil?
      usr_edit.team_adopt=!params["adopt"].nil?
      usr_edit.save
      return { state: true, message: "Сохранено" }.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }


  post('/team/create') {
    begin
      logger.info params
      content_type :js
      user=session[:user]
      if !Team[:title=>params["title"].strip].nil?
        return {state: false,message:'Комманда с таким именем уже есть'}.to_json
      end
      if !user.team.nil?
        return {state: false,message:"Вы состоите в комманде #{user.team.title}, нужно сначала покинуть комманду"}.to_json
      end
      team=Team.new(:title=>params["title"].strip)
      team.save
      user.team=team
      user.captain=true
      user.team_adopt=true
      user.save
      return {state: true,message:'Комманда создана, вы назначены капитаном'}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  post('/team/join') {
    content_type :js
    begin
      logger.info params
      content_type :js
      user=session[:user]

      if !user.team.nil? && user.captain
        return {state: false,message:"Вы капитан в комманде #{user.team.title}, нужно сначала сложить полномочия"}.to_json
      end
      if params["team"].to_i==0
        user.team=nil
        user.team_adopt=false
        user.save
        return {state: true,message:"Вы покинули комманду"}.to_json
      end
      # if user.team.nil?
      #   user.team=Team[params["team"].to_i]
      #   user.save
      #   return {state: true,message:"Заявка на вступление отправлена"}.to_json
      # end

      team=Team[params["team"].to_i]

      user.team=team
      user.captain=false
      user.team_adopt=false
      user.save
      return {state: true,message:"Заявка на вступление отправлена"}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :game
  }
end
