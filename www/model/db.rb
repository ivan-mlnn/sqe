require 'sequel'
require 'json'
require 'telegram/bot'


module Model
  DB = Sequel.connect('postgres://sqe:sqe@localhost/sqe',:max_connections=>20)
  DB.extension :pg_hstore
  DB.extension :pg_array
  Sequel.extension :pg_hstore
  Sequel.extension :pg_array_ops
  Sequel.split_symbols = true
  BOT=Telegram::Bot::Client.new('telegram bot token')#https://core.telegram.org/bots#6-botfather
  class Team < Sequel::Model(:teams)
    one_to_many :users
    one_to_many :status ,:class=>:Status

    def curent_levels
      self.status_dataset.where(:end=>nil,:game_id=>self.active_game).order(:id).all
    end
    def get_level(id)
      self.status_dataset.where(:end=>nil,:level_id=>id.to_i).first
    end
    def tg_notify(str)
      Thread.new { 
        self.users_dataset.exclude(:tgid=>nil).where(:team_adopt).map(:tgid).each { |e| 
          puts BOT.api.send_message(chat_id:e,text: str)
         }
      }
        
    end
  end

  class User < Sequel::Model(:users)
    many_to_one :team
    # def game_admin?(game=nil)
    #   if self.admin
    #     return true
    #   elsif self.team.nil?
    #     return false
    #   elsif game.nil?
    #     return false
    #   elsif !self.team_adopt
    #     return false
    #   elsif self.team.id==game.team_id
    #     return true
    #   else
    #     return false
    #   end
    # end

    def game_play?()
      if self.admin
        return false
      elsif self.team.nil?
        return false
      elsif !self.team_adopt
        return false
      end
      game=Game[self.team.active_game]
      if game.nil?
        return false
      end

      if game.run?
        return true
      elsif game.owner?(self)
        return true
      end

      return false
    end
  end



  class Game < Sequel::Model(:games)
    one_to_many :status ,:class=>:Status
    one_to_many :levels
    def run?
      self.start<= Time.now && self.stop> Time.now && !self.closed
    end
    def state(user)
      team=user.team

      st_ds=DB[:status].where(:team_id=>team.id,:game_id=>self.id)
      if self.run?
        if st_ds.count==0
          return :start
        elsif true
          return :ingame
        else
          return :debug_2
        end
      elsif self.owner?(user) && st_ds.count>0
        return :intest
      elsif self.closed
        return :closed
      elsif self.start>= Time.now
        return :wait
      elsif self.stop< Time.now
        return :end
      end
    end

    def start_game(user)
      team=user.team
      next_lvl=self.get_next_level(nil,team)
      start_time=self.owner?(user) ? start_time=Time.now : self.start
      next_lvl.each { |e|
        sts=Status.new
        sts.team=team
        sts.game=self
        sts.level=Level[e]
        sts.enter=start_time
        if sts.level.answer.to_a.empty?
          sts.spoiler=start_time
        end
        sts.save
           l_print_name=sts.level.hide_title ? "Уровень № #{sts.level.number}" : "(№#{sts.level.number}) #{sts.level.title}"
       DB[:gamelog].insert(:action=>'level_enter',:msg=>"Вход на уровень '#{l_print_name}' ",:ts=>start_time,:game_id=>self.id,:level_id=>sts.level_id,:team_id=>sts.team_id)
       Team[sts.team_id].tg_notify("Вход на уровень '#{l_print_name}' ")
      }
      
    end

    def process_state(user ,ts=nil,input=nil,team=nil)
      team= team.nil? ? user.team : team
      now=ts.nil? ? Time.now : ts
      # states=Status[:game=>self,:team=>team,:end=>nil]
      states=self.status_dataset.where(:end=>nil,:team_id=>team.id).all
      puts '-'*30
      puts states.inspect
      puts '-'*30
      states.each { |e|


        if (e.enter+e.level.duration<=now && e.level.type !='infinite' && e.level.type !='infinite_olympic') || self.stop< now
          #timeout
          e.penalty+=e.level.penalty
          e.end=e.enter+e.level.duration
          l_print_name=e.level.hide_title ? "Уровень № #{e.level.number}" : "(№#{e.level.number}) #{e.level.title}"

          e.save
          DB[:gamelog].insert(:action=>'level_timeout',:msg=>"Начислен Штраф #{e.level.penalty} сек. за слив уровня '#{l_print_name}' ",:ts=>now,:game_id=>self.id,:level_id=>e.level_id,:team_id=>e.team_id)
          team.tg_notify('Уровень слит...')
        elsif e.spoiler.nil?
          puts '-'*30
          puts 'need spoiler '*10
          puts '-'*30
        elsif e.all_codes_take?
          puts '-'*30
          puts 'all codes'*10
          puts '-'*30

          e.end=now
          e.save
          team.tg_notify('Все коды взяты!!!')
        else
          puts '-'*30
          puts 'WTF? '*10
          puts '-'*30

        end
      }
      # TODO: fix сквозные уровни получат баг здесь FIXed
       if DB[:status].where(:status__game_id=>self.id,:team_id=>team.id,:end=>nil).left_join(:levels,:id=>:level_id).exclude(:type=>'tranzit').count==0

      # if DB[:status].where(:game_id=>self.id,:team_id=>team.id,:end=>nil).count==0
        last_end=DB[:status].where(:status__game_id=>self.id,:team_id=>team.id).left_join(:levels,:id=>:level_id).exclude(:end => nil,:type=>'tranzit').reverse(:end).get(:end)
        # last_end=DB[:status].where(:game_id=>self.id,:team_id=>team.id).and.exclude(:end => nil).reverse(:end).get(:end)
        nxt=self.get_next_level(nil,team)
        nxt.each { |e|
          sts=Status.new
          sts.team=team
          sts.game=self
          sts.level=Level[e]
          sts.enter=last_end.nil? ? now : last_end
          if sts.level.answer.to_a.empty?
            sts.spoiler=sts.enter
          end
          sts.save
        l_print_name=sts.level.hide_title ? "Уровень № #{sts.level.number}" : "(№#{sts.level.number}) #{sts.level.title}"
       DB[:gamelog].insert(:action=>'level_enter',:msg=>"Вход на уровень '#{l_print_name}' ",:ts=>sts.enter,:game_id=>self.id,:level_id=>sts.level_id,:team_id=>sts.team_id)
       Team[sts.team_id].tg_notify("Вход на уровень '#{l_print_name}' ")
        }
      end
    end


    # def level_end?(team)
    #   states=Status[:game=>self,:team=>team]
    #   result=false
    #   states.each { |e|
    #     e.done

    #   }
    # end
    def get_next_level(level,team)
      seq=level.nil? ? 0 : level.sequence
      num=self.levels_dataset.where{sequence > seq}.order(:sequence).left_join(:status ,:levels__id=>:status__level_id, :status__team_id=>team.id).where(:status__id=>nil).get(:sequence)
      return num.nil? ? [] : self.levels_dataset.where(:sequence=>num).order(:number,:id).select_map(:id)
    end

    def owner?(user)
      return user.admin || (DB[:gameowner].where(:game_id=>self.id,:user_id=>user.id).empty? == false )
    end
  end
  class Level < Sequel::Model(:levels)
    one_to_many :status ,:class=>:Status
    many_to_one :game

  end

  class Code < Sequel::Model(:codes)

  end
  class Hint < Sequel::Model(:hints)

  end
  class Status < Sequel::Model(:status)
    many_to_one :team
    many_to_one :level
    many_to_one :game


    def all_codes_take?
      take=DB[:gamelog].join(:codes, :id=>:code_id).where(:valid).where(:gamelog__level_id=>self.level_id).where(:team_id=>self.team_id).where(:action=>'code_input').where(:main).count
      need=self.level.need_codes<=0 ? DB[:codes].where(:level_id=>self.level_id,:main=>true).count : self.level.need_codes
      return take>=need
    end

    def codes_list()
      a= DB[:codes].where(:codes__level_id=>self.level_id).left_join(:gamelog, :code_id=>:id ,:action=>'code_input',:team_id=>self.team_id).select_all(:codes).select_append(:input,:valid, :code_id,:user_id,:ts)
      if self.level.type=='olympic' or self.level.type=='olympic_bonus'
     	 a=a.order(:number).all
      else
     	 a=a.order(:sektor,:number).all
      end
      a=a.map { |e|
        e[:user]=User[e[:user_id]] if !e[:user_id].nil?
        e
      }

    end
    def codes_stat()
      res={}
      # take main
      res[:tm]=DB[:gamelog].where(:valid=>true,:gamelog__level_id=>self.level_id,:team_id=>self.team_id,:action=>'code_input').join(:codes, :id=>:code_id).where(:main).count
      # take bonus
      res[:tb]=DB[:gamelog].where(:valid=>true,:gamelog__level_id=>self.level_id,:team_id=>self.team_id,:action=>'code_input').join(:codes, :id=>:code_id).where(:main=>false).count
      # main count
      res[:mc]=DB[:codes].where(:level_id=>self.level_id,:main=>true).count
      # bonus count
      res[:bc]=DB[:codes].where(:level_id=>self.level_id,:main=>false).count
      #need
      res[:n]=self.level.need_codes<=0 ? res[:mc] : self.level.need_codes
      return res
    end
    def process_input(data,user=nil,ts=nil)
      # now=Time.now
      now=ts.nil? ? Time.now : ts
      if self.spoiler.nil?
        if self.level.answer.member?(data)
          self.spoiler=now
          self.save
          DB[:gamelog].insert(:valid=>true,:action=>'spoiler_input',:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)
          return {state:true,:type=>:spoiler,:ts=>now}
        else
          DB[:gamelog].insert(:valid=>false,:action=>'spoiler_input',:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)

          return {state:false,:type=>:spoiler,:ts=>now}
        end
      else
        c=DB[:codes].where(:level_id=>self.level_id, data=>Sequel.pg_array(:code).any).first
        if c.nil?
          DB[:gamelog].insert(:valid=>false,:action=>'code_input_wrong',:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)
          return {state:false,:type=>:code,:ts=>now}
        else
          if self.level.type=='fallout' && !c[:main]
         	 l=DB[:gamelog].where(:code_id=>c[:id],:action=>'code_input',:valid=>true,:game_id=>self.game_id,:level_id=>self.level_id).order(:ts).first
          else
	         l=DB[:gamelog].where(:code_id=>c[:id],:action=>'code_input',:valid=>true,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id).order(:ts).first
          end
          if l.nil?
            DB[:gamelog].insert(:code_id=>c[:id],:valid=>true,:action=>'code_input',:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)
            if c[:bonus].to_i>0
              self.bonus+=c[:bonus].to_i
              self.save
              DB[:gamelog].insert(:code_id=>c[:id],:valid=>true,:action=>'code_bonus',:msg=>"Начислен Бонус #{c[:bonus]} сек. за код №#{c[:number]}(Сектор #{c[:sektor]}) ",:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)

            elsif c[:bonus].to_i<0
              self.penalty+=c[:bonus].to_i
              self.save
              DB[:gamelog].insert(:code_id=>c[:id],:valid=>true,:action=>'code_penalty',:msg=>"Начислен Штраф #{c[:bonus]} сек. за код №#{c[:number]}(Сектор #{c[:sektor]}) ",:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)

            end
            return {state:true,:type=>:code,:code=>c,:ts=>now}
          else
            DB[:gamelog].insert(:code_id=>c[:id],:valid=>true,:action=>'code_input_dup',:ts=>now,:game_id=>self.game_id,:level_id=>self.level_id,:team_id=>self.team_id,:user_id=>user.id,:input=>data)
            return {state:true,:type=>:code_dup,:code=>c,:log=>l,:ts=>now}
          end
        end
      end
    end

  end

end
