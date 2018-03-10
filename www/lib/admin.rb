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
  get('/admin/edit') {

    erb :admin_edit
  }
  post('/admin/upload/:id'){|id|
    begin
    user=session[:user]
    game=Game[id.to_i]
    halt 'только для админов или авторов' if !game.owner?(user)
    path=File.expand_path(File.dirname(__FILE__) + '/../public/data/')
    if !Dir.exist?(File.join(path,game.id.to_s))
        Dir.mkdir(File.join(path,game.id.to_s))
    end
    params['files'].each { |file| 
      filename=file[:filename]
      h=XXhash.xxh32(filename, game.id).abs.to_s
      ext=filename.split('.').last.downcase
      fp=File.join(path,game.id.to_s,h+"."+ext)
      
      File.open(fp, "w") do |f|
         f.write(file[:tempfile].read)
      end
      DB[:files].insert(:game_id=>game.id,:name=>filename,:path=>File.join('/data',game.id.to_s,h+"."+ext))
      logger.info fp
    }
    return {state:true,msg:'ok'}.to_json
    rescue Exception => e
      logger.error e
      { state: false, msg: e.message }.to_json
    end
  }
  get('/admin/game/close/:id'){
      content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return {:state=>false,:msg=>'нет доступа'}.to_json  if !game.owner?(user) 
      # return {:state=>false,:msg=>'игра уже закрыта'}.to_json  if game.closed
      game.closed=true
      game.save  
      return {:state=>true,:msg=>'игра закрыта'}.to_json 
      
 rescue Exception => e
      logger.error e
      { state: false, msg: e.message }.to_json
    end
}

  get('/admin/files/:id'){|id|
  begin
    user=session[:user]
    game=Game[id.to_i]
    halt 'только для админов или авторов' if !game.owner?(user)
    lst=DB[:files].where(:game_id=>game.id).order(:name).all
    erb :admin_files,:layout=>false , :locals=>{:files=>lst}
  rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  get('/admin/level/codes_list_ko/:game_id'){|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
       halt 'только для админов или авторов' if !game.owner?(user)
     
      ko=DB['SELECT DISTINCT ko from codes JOIN levels ON codes.level_id=levels.id WHERE levels.game_id=?',game.id].all
      ko<<{ko:'х.з.'}
      return ko.uniq.to_json
    rescue Exception => e
      logger.error e
      halt e.message
    end
  }
  get('/admin2/game/edit/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
       halt 'только для админов или авторов' if !game.owner?(user)
     

    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :admin_desktop,:layout=>false , :locals=>{:game_id=>game.id}
  }
  get('/admin/game/edit/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
       halt 'только для админов или авторов' if !game.owner?(user)
     
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :admin_game_edit, :locals=>{:game_id=>game.id}
  }
  get('/admin/game/level_editor/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
       halt 'только для админов или авторов' if !game.owner?(user)
     
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :admin_game_level_editor, :locals=>{:level=>level},:layout=>false
  }
  get('/admin2/game/level_editor/:id') {|id|
    begin
      # redirect if id=="game"
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
       halt 'только для админов или авторов' if !game.owner?(user)
     
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :admin2_game_level_editor, :locals=>{:level=>level},:layout=>false
  }
  post('/admin/level/codes_list/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
       halt 'только для админов или авторов' if !game.owner?(user)
     
      return DB[:codes].where(:level_id=>level.id).order(:number).map{|e|
        e[:code]=e[:code].join(',')
        #e[:bonus]=Time.at(e[:bonus]).utc.strftime('%H:%M:%S')
        e[:main]=e[:main] ? 'Осн' : 'Бнс'
        e
      }.to_json
    rescue Exception => e
      logger.error e
      halt e.message
    end
    # erb :admin_game_level_editor, :locals=>{:level=>level},:layout=>false
  }
  post('/admin/level/codes_save') {
    begin
      content_type :js
      user=session[:user]
      d=Hash[params.map{|k,v| [k.to_sym,v]}]

      level=Level[d[:level_id].to_i]
      game=Game[level.game_id]
      halt 'game closed' if game.closed
       halt 'только для админов или авторов' if !game.owner?(user)
     
      d[:code].split(',').map { |e| UnicodeUtils.downcase(e).strip.gsub(/\s/,'') }.each { |e|  
      c=DB[:codes].where(:level_id=>level.id, e=>Sequel.pg_array(:code).any).count
      if c>0 && d[:isNewRecord]
         return { isError:true,state: false, message: 'такой код уже есть:'+e }.to_json
      end
      }
      if d[:isNewRecord] || d[:id].nil? || d[:id].empty?
        number= d[:number].empty? ? DB[:codes].where(:level_id=>level.id).max(:number).to_i+1 : d[:number].to_i
        last_sector=DB[:codes].where(:level_id=>level.id).count>0 ? DB[:codes].where(:level_id=>level.id).select(:sektor).order(:number).last[:sektor].to_s : 'Локация'
        sektor= d[:sektor].empty? ? last_sector : d[:sektor].to_s
        code=Sequel.pg_array(d[:code].split(',').map { |e| UnicodeUtils.downcase(e).strip.gsub(/\s/,'') })
        #bonus=0
        #d[:bonus].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| bonus+=v*60**i} #another magic
        bonus=d[:bonus]
        main=d[:main].to_s=='Осн'
        DB[:codes].insert(:level_id=>level.id,:number=>number,:sektor=>sektor,:code=>code,:main=>main,:bonus=>bonus,:note=>d[:note].strip,:ko=>d[:ko].strip,:hint=>d[:hint].strip,:title=>d[:title])
        return {state:true,message:'Сохранено',reload:true}.to_json
      else
        number= d[:number].empty? ? DB[:codes].where(:level_id=>level.id).max(:number).to_i+1 : d[:number].to_i
        code=Sequel.pg_array(d[:code].split(',').map { |e| UnicodeUtils.downcase(e).strip.gsub(/\s/,'') })
        #bonus=0
        #d[:bonus].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| bonus+=v*60**i} #another magic
        bonus=d[:bonus]
        main=d[:main].to_s=='Осн'
        DB[:codes].where(:id=>d[:id]).update(:number=>number,:sektor=>d[:sektor],:code=>code,:main=>main,:bonus=>bonus,:note=>d[:note].strip,:ko=>d[:ko].strip,:hint=>d[:hint],:title=>d[:title])
        return {state:true,message:'Сохранено',reload:false}.to_json
      end



    rescue Exception => e
      logger.error e
      { state: false, message: e.message ,isError:true}.to_json
    end
    # erb :admin_game_anounce_editor, :locals=>{:game=>game},:layout=>false
  }
  post('/admin/level/codes_del'){
    begin
      content_type :js
      user=session[:user]

      d=Hash[params.map{|k,v| [k.to_sym,v]}]
      code=Code[d[:id].to_i]
      level=Level[code.level_id]
      game=Game[level.game_id]
       halt 'только для админов или авторов' if !game.owner?(user)
     
      if d[:id].empty?
        return {state:false,message:'error',reload:true,isError:true}.to_json
      else
        DB[:codes].where(:id=>d[:id]).delete()
        return {state:true,message:'Удалено',reload:true}.to_json
      end
   rescue Exception => e
      logger.error e
      { state: false, message: e.message,isError:true }.to_json
    end
  }
get('/admin/level_delete/:id'){|id|
 begin
      content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
      
       halt 'только для админов или авторов' if !game.owner?(user)
     
      DB[:codes].where(:level_id=>id).delete()
      DB[:hints].where(:level_id=>id).delete()
      DB[:levels].where(:id=>id).delete()
      { state: true }.to_json
   rescue Exception => e
      logger.error e
      { state: false, message: e.message,isError:true }.to_json
    end
}
  post('/admin/level/hints_del'){
    begin
      content_type :js
      user=session[:user]
       d=Hash[params.map{|k,v| [k.to_sym,v]}]
      hint=Hint[d[:id].to_i]
      level=Level[hint.level_id]
     game=Game[level.game_id]
      
       halt 'только для админов или авторов' if !game.owner?(user)
     
      if d[:id].empty?
        return {state:false,message:'error',reload:true,isError:true}.to_json
      else
        DB[:hints].where(:id=>d[:id]).delete()
        return {state:true,message:'Удалено',reload:true}.to_json
      end
   rescue Exception => e
      logger.error e
      { state: false, message: e.message,isError:true }.to_json
    end
  }
  post('/admin/level/hints_list/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      level=Level[id.to_i]
      game=Game[level.game_id]
       halt 'только для админов или авторов' if !game.owner?(user)
     
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
  post('/admin/level/hints_save') {
    begin
      content_type :js
      user=session[:user]
      d=Hash[params.map{|k,v| [k.to_sym,v]}]

      level=Level[d[:level_id].to_i]
      game=Game[level.game_id]
halt 'game closed' if game.closed
       halt 'только для админов или авторов' if !game.owner?(user)
     
      timer=0
      if d[:isNewRecord] || d[:id].nil? || d[:id].empty?
        tmp_timer=d[:timer].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| timer+=v*60**i}
        timer= d[:timer].empty? ? DB[:hints].where(:level_id=>level.id).max(:timer).to_i+60 : timer

        #another magic
        DB[:hints].insert(:level_id=>level.id,:timer=>timer,:text=>d[:text],:title=>d[:title])
        return {state:true,message:'Сохранено',reload:true}.to_json
      else
        tmp_timer=d[:timer].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| timer+=v*60**i}
        timer= d[:timer].empty? ? DB[:hints].where(:level_id=>level.id).max(:timer).to_i+60 : timer
        DB[:hints].where(:id=>d[:id]).update(:timer=>timer,:text=>d[:text],:title=>d[:title])
        return {state:true,message:'Сохранено',reload:false}.to_json
      end



    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :admin_game_anounce_editor, :locals=>{:game=>game},:layout=>false
  }
  post('/admin/level/level_save') {
    begin
      content_type :js
      user=session[:user]
      level=Level[params["id"].to_i]
      game=Game[level.game_id]
halt 'game closed' if game.closed
       halt 'только для админов или авторов' if !game.owner?(user)
     
      d=Hash[params.map{|k,v| [k.split[0].to_sym,v]}] #magic here)))
      level.title=d[:title]
      level.number=d[:number]
      level.sequence=d[:sequence]
      level.need_codes=d[:need_codes]
      level.question=d[:question]
      level.spoiler=d[:spoiler]
      level.type=d[:type]
      level.answer=d[:answer].split(',').map { |e| e.strip }
      duration=0
      d[:duration].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| duration+=v*60**i} #another magic
      level.duration=duration
      code_hint_timer=0
      d[:code_hint_timer].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| code_hint_timer+=v*60**i} #another magic
      level.code_hint_timer=code_hint_timer
      penalty=0
      d[:penalty].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| penalty+=v*60**i} #another magic
      level.penalty=penalty
      level.hide_title=!d[:hide_title].nil?

      level.save

      return {state:true,message:'Сохранено'}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :admin_game_anounce_editor, :locals=>{:game=>game},:layout=>false
  }

  get('/admin/game/anounce_editor/:id') {|id|
    begin
      # content_type :js
      user=session[:user]
      game=Game[id.to_i]
       halt 'только для админов или авторов' if !game.owner?(user)
     
      autors=DB[:gameowner].where(:game_id=>game.id).map(:user_id)
    rescue Exception => e
      logger.error e
      halt e.message
    end
    erb :admin_game_anounce_editor, :locals=>{:game=>game,:autors=>autors},:layout=>false
  }
  post('/admin/game/anounce_save') {
    begin
      content_type :js
      user=session[:user]
      game=Game[params["id"].to_i]

      halt 'только для админов или авторов' if !game.owner?(user)
      halt 'game closed' if game.closed
      if user.admin
        # game.team_id=params["team_id"]
        DB[:gameowner].where(:game_id=>game.id).delete()
        params["users"].map { |e| e.to_i }.each { |e| 
          DB[:gameowner].insert(:game_id=>game.id,:user_id=>e)
        } if !params["users"].nil?
      end
      game.anounce=params["anounce"]
      game.title=params["title"]
      game.start=params["start"]
      game.stop=params["stop"]
      game.save
      return {state:true,message:'Сохранено'}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :admin_game_anounce_editor, :locals=>{:game=>game},:layout=>false
  }
  get('/admin/game/level_list/:id') {|id|
    begin
      content_type :js
      user=session[:user]
      game=Game[id.to_i]
       halt 'только для админов или авторов' if !game.owner?(user)
     
      resp=[]
      resp<<{:link=>"/admin/game/anounce_editor/#{game.id}",:title=>'Анонс',id:"game_anounce"}
      resp+=DB[:levels].select(:title,:id).where(:game_id=>game.id).order_by(:sequence).map { |e| e[:link]="/admin/game/level_editor/#{e[:id]}";e }
      return {:state=>true, :list=>resp}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
    # erb :admin_game_edit, :locals=>{:game_id=>game.id}
  }

  get('/admin/game/create') {
    begin
      content_type :js
      user=session[:user]
      if !user.admin
        return {state:false,message:'только для админов'}.to_json
      end
      a=DB[:games].insert(:title=>params['title'],:anounce=>'',:start=> Time.now,:stop=> Time.now)
      return {state:true,message:'ok',id:a}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  get('/admin/game/create_level') {
    begin
      content_type :js
      user=session[:user]
      id=params["game_id"]
      game=Game[id.to_i]

      halt 'только для админов или авторов' if !game.owner?(user)

      
      a=DB[:levels].insert(:title=>params['title'],:game_id=>params["game_id"])
      return {state:true,message:'ok',id:a}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
  post('/tmp/:id') {|id|
    begin
      content_type :js
      user=session[:user]
      return params.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }

end
