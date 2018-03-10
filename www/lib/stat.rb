# encoding: UTF-8
# rubocop:disable Style/StringLiterals
# require File.expand_path(File.dirname(__FILE__) + '/log/log')
STAT_SUM_SQL="SELECT
  t.title_l,
  t.title_t,
  t.lt,
  t.l_id,
  sum(EXTRACT(EPOCH FROM t.clean_time)) AS clean_time,
  sum(EXTRACT(EPOCH FROM t.bonus))      AS bonus,
  sum(EXTRACT(EPOCH FROM t.penalty))    AS penalty,
  sum(EXTRACT(EPOCH FROM t.pause))      AS pause,
  CASE WHEN t.lt = 'removed'
    THEN 0
  WHEN t.lt = 'removed_w_bonus' OR t.lt = 'infinite' OR t.lt = 'olympic_bonus' OR t.lt = 'fallout' OR t.lt = 'infinite_olympic'
    THEN
      sum(EXTRACT(EPOCH FROM INTERVAL '0' - t.bonus + t.penalty - t.pause))
  ELSE
    sum(EXTRACT(EPOCH FROM t.clean_time - t.bonus + t.penalty - t.pause))
  END
                                        AS sm
FROM (SELECT
        teams.title                             AS title_t,
        levels.title                            AS title_l,
        levels.type                             AS lt,
        levels.id                               AS l_id,
        levels.number                           AS l_num,
        CASE WHEN status.end ISNULL
          THEN
            now() - status.enter
        ELSE
          status.end - status.enter
        END
                                                AS clean_time,

        status.bonus * INTERVAL '1 second'      AS bonus,
        status.penalty * INTERVAL '1 second'    AS penalty,
        status.pause_time * INTERVAL '1 second' AS pause

      FROM status
        JOIN levels ON status.level_id = levels.id
        JOIN teams ON status.team_id = teams.id
      WHERE status.game_id = ?
      ORDER BY levels.number) AS t
GROUP BY t.title_l, title_t, t.lt, t.l_id, l_num
ORDER BY t.l_num

"
require 'oj'
require 'json'
include Model
Sequel.extension :core_refinements
using Sequel::CoreRefinements
class SQE < Sinatra::Base
  register Sinatra::Reloader
  get('/stat/:id') do
    user=session[:user]

    game=Game[params["id"]]
    halt 'нет доступа'  if !game.owner?(user) && !game.closed
    columns=DB[:levels].where(:game_id=>game.id).select(:id,:title).order(:sequence).map { |e|
      r={}
      # r[:id]=e[:id]
      r[:width]=100
      r[:field]="lvl_#{e[:id]}"
      r[:title]=e[:title]
      r
    }
    columns<<{:width=>100,field:'summary',title:'Итог'}
    erb :stat_game,:layout=>false ,:locals=>{:game=>game,:cols=>columns}
  end

  def format_interval(data)
    s= data<0 ? '-' : ''
    s+=Time.at(data.abs).utc.strftime("%H:%M:%S<font size='1'>.%L</font>")
    return s
  end
post('/stat/team_filter/:id'){|id|

 logger.info params
    content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return [{:value=>'',:text=>'нет доступа'}] .to_json  if !game.owner?(user) && !game.closed 
     if params['stat']
     res= DB[:status].join(:teams,:id=>:team_id).where(:status__game_id=>id).distinct(:teams__title,:teams__id).map{|e| {:text=>e[:title], :value=>e[:id]} }
     else
     res= DB[:gamelog].join(:teams,:id=>:team_id).where(:gamelog__game_id=>id).distinct(:teams__title,:teams__id).map{|e| {:text=>e[:title], :value=>e[:id]} }
     res=res.unshift({:text=>'--Все--',:selected=>true,:value=>''})
     end
     return res.to_json
 rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
}
post('/stat/levels_filter/:id'){|id|

 logger.info params
    content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return [{:value=>'',:text=>'нет доступа'}] .to_json  if !game.owner?(user) && !game.closed 
     if params['stat']
     res= DB[:status].join(:levels,:id=>:level_id).where(:status__game_id=>id).order(:levels__number).distinct(:levels__title,:levels__id,:levels__number).map{|e| {:text=>e[:title], :value=>e[:id]} }
     else
     res= DB[:gamelog].join(:levels,:id=>:level_id).where(:gamelog__game_id=>id).order(:levels__number).distinct(:levels__title,:levels__id,:levels__number).map{|e| {:text=>e[:title], :value=>e[:id]} }
     res=res.unshift({:text=>'--Все--',:selected=>true,:value=>''})
     end
     return res.to_json
 rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
}
post('/stat/edit/:id'){
      content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return {:state=>false,:msg=>'нет доступа'}.to_json  if !game.owner?(user) 
      return {:state=>false,:msg=>'игра закрыта'}.to_json  if game.closed
      if DB[:status].where(:level_id=>params['level'],:team_id=>params['team']).count==0
        return {state:false,msg:'Команда еще не была на уровне!!!!'}.to_json
      end
       tval=0
        params['time'].split(':').map{|e,i| e.to_i}.reverse.each_with_index{|v,i| tval+=v*60**i} #another magic
        
      if params['type']=='bonus'
        msg="Начислен бонус #{tval} сек. Начислил #{user.title}(#{user.login}): '#{params['message']}' "
        DB['update status set bonus=bonus+? where level_id=? and team_id=?',tval,params['level'],params['team']].update
        DB[:gamelog].insert(:action=>'admin_bonus',:msg=>msg,:ts=>Time.now,:game_id=>game.id,:level_id=>params['level'],:team_id=>params['team'])
        return {state:true,msg:msg}.to_json
      elsif params['type']=='penalty'
        msg="Начислен штраф #{tval} сек. Начислил #{user.title}(#{user.login}): '#{params['message']}' "
        DB['update status set penalty=penalty+? where level_id=? and team_id=?',tval,params['level'],params['team']].update
        DB[:gamelog].insert(:action=>'admin_penalty',:msg=>msg,:ts=>Time.now,:game_id=>game.id,:level_id=>params['level'],:team_id=>params['team'])
        return {state:true,msg:msg}.to_json
        else
          return {state:false,msg:'что то пошло не так'}.to_json
      end
 rescue Exception => e
      logger.error e
      { state: false, msg: e.message }.to_json
    end
}



  get('/stat/summary/:id') {|id|
    logger.info params
    content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return { total: 1, rows: [{:id=>0,:ts=>Time.now.to_f*1000,:t_title=>'нет доступа'}] }.to_json  if !game.owner?(user) && !game.closed 

      ds=DB[STAT_SUM_SQL,id.to_i]
      t=ds.to_hash_groups(:title_t)
      columns=DB[:levels].where(:game_id=>id).select(:id,:title).map { |e|
        r={}
        r[:id]=e[:id]
        r[:field]="lvl_#{e[:id]}"
        r[:title]=e[:title]
        r
      }
      rows=[]
      t.each_pair { |name, val|
        row={}
        row[:t_title]=name
        summary=0
        row[:sum_clean]=0
        row[:sum_bonus]=0
        row[:sum_sum]=0
        row[:sum_penalty]=0
        row[:sum_pause]=0
        columns.each { |e|
          l=val.find{|x| x[:l_id]==e[:id]}
          if !l.nil?
            str=format_interval(l[:sm].to_f)
            str+='<br><font color="blue">'+format_interval(l[:clean_time].to_f)+"</font>"
            str+='<br><font color="green">'+format_interval(l[:bonus].to_f)+"</font>" if l[:bonus]!=0
            str+='<br><font color="red">'+format_interval(l[:penalty].to_f)+"</font>" if l[:penalty]!=0
            # str+='<br>'+format_interval(l[:pause].to_f)
            row[e[:field]]= str#format_interval(l[:sm].to_f)

            #row["#{e[:field]}_data"]=l[:sm].to_f
            logger.info row
            logger.info l
            row[:sum_clean]+= l[:clean_time].to_f
            row[:sum_bonus]+= l[:bonus].to_f
            row[:sum_sum]+= l[:sm].to_f
            row[:sum_penalty]+= l[:penalty].to_f

          end

        }
        row[:summary]=format_interval(row[:sum_sum].to_f)
        row[:summary]+='<br><font color="blue">'+format_interval(row[:sum_clean].to_f)+"</font>"
        row[:summary]+='<br><font color="green">'+format_interval(row[:sum_bonus].to_f)+"</font>" if row[:sum_bonus]!=0
        row[:summary]+='<br><font color="red">'+format_interval(row[:sum_penalty].to_f)+"</font>" if row[:sum_penalty]!=0
        rows<<row
      }
      rows.sort!{|x,y| x[:sum_clean]<=>y[:sum_clean]}
      rows.sort!{|x,y| x[:sum_bonus]<=>y[:sum_bonus]}
      rows.sort!{|x,y| x[:sum_sum]<=>y[:sum_sum]}

      {total: rows.length, rows: rows}.to_json
    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end

  }



  get('/stat/log/:id') {|id|
    logger.info params
    content_type :js
    begin
      user=session[:user]
      game=Game[params["id"]]
      return { total: 1, rows: [{:id=>0,:ts=>Time.now.to_f*1000,:t_title=>'нет доступа'}] }.to_json  if  !game.owner?(user) && !game.closed
      limit=params["rows"].nil? ? 50 : params["rows"].to_i
      offset=params["page"].nil? ? 0 : (params["page"].to_i-1)*limit
      # cnt=DB[:gamelog].where(:game_id=>game.id).count
      
      rows=DB[:gamelog].
        join(:teams,:id=>:team_id).
        left_join(:levels,:id=>:gamelog__level_id).
        left_join(:users,:id=>:gamelog__user_id).
        left_join(:codes,:id=>:gamelog__code_id).
        where(:gamelog__game_id=>id)
     rows=rows.and(:gamelog__team_id=>params['team'].to_i) if params['team'].to_i>0
     rows=rows.and(:gamelog__level_id=>params['level'].to_i) if params['level'].to_i>0
     rows=rows.and(:gamelog__action=>params['action'].to_s) if params['action'].to_s.length>0
     rows=rows.and(:gamelog__valid=>params['valid'].to_s=="true" ? true : false ) if params['valid'].to_s.length>0 
     cnt=rows.count
     rows=  rows.select_all(:gamelog).
      select_append(
        Sequel.as(:teams__title,:team),
        # Sequel.as(:users__title,:user),
        Sequel.as(:users__title.sql_string+' ['+:users__login.sql_string+']',:user),
        Sequel.as(:levels__title,:level),
        Sequel.as(:codes__number,:code)
      ).reverse(:ts,:id).limit(limit,offset).all
      {total: cnt, rows: rows}.to_json

    rescue Exception => e
      logger.error e
      { state: false, message: e.message }.to_json
    end
  }
end
