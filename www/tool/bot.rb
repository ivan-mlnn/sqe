#!/usr/local/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../model/db')
require 'logger'
require "unicode_utils"
include Model
logger = Logger.new(File.dirname(__FILE__) + '/../log/bot.log', 10, 1024000)
SR=/^\/start (\d+)_(\S{32})/i
require 'telegram/bot'

token = 'telegram bot token' # https://core.telegram.org/bots#6-botfather
def code_status(r)
	str=''
	if (r[:valid] && r[:type] == :code) 
        str += "\xE2\x9C\x85"
        if (r[:main]) 
            str += '🔦'
        else 
            str += '🎉'
        end
        str += ' Код ' + r[:sektor].to_s + ': №' + r[:number].to_s + ' принят '
        if (r[:bonus] != 0) 
            if (r[:bonus] > 0) 
                str += ' <b>+</b>'
             else 
                str += ' <b>-</b>'
            end

            str += "#{r[:bonus]}s"
        end
        str += ' <b>КО:</b> ' + r[:ko].to_s + ' '

        str += "\xE2\x9C\x85"

        
        
     elsif (!r[:valid] && r[:type] == :code) 
        str += "\xE2\x9D\x8C"
        str += ' Код "' + r[:input] + '" не принят '
        str += "\xE2\x9D\x8C"

     elsif (r[:valid] && r[:type] == :code_dup) 
        str += "\xE2\x9A\xA0"
        str += '<b> Повтор </b>' + r[:sektor] + ': №' + r[:number].to_s + ' [' + r[:ts].to_s + '], <b> Вбил: </b>' + r[:user].to_s
        str += '<b> КО:</b> ' + r[:ko].to_s

        str += "\xE2\x9A\xA0"
    end
    return str
end
Telegram::Bot::Client.run(token) do |bot|

begin
  bot.listen do |message|
    logger.info "#{message.from.first_name} #{message.from.last_name}(#{message.from.username}): #{message.text}"
    case message.text
    when SR
    	m=SR.match(message.text)
    	id=m[1]
    	tkn=m[2]
    	u=User[id]
    	tgtoken=Digest::MD5.hexdigest "#{u.id}-+-#{u.title}^42%#{u.password}~``#{u.login}@`" 
    	if tkn==tgtoken
    		DB[:users].where(:tgid=>message.from.id).update(:tgid=>nil)
    		u.tgid=message.from.id
    		u.save
    		bot.api.send_message(chat_id: message.from.id, text: "Аккаунт телеги(id:#{message.from.id}) успешно привязан к профилю #{u.title}(#{u.login}) в движке")
    	else
    		bot.api.send_message(chat_id: message.from.id, text: "Авторизация неудачна, бота надо подключать по ссылке из профиля движка https://sqe.mlnn.ru/profile")
    	end
    else
    	ts=Time.now
      	user=User[:tgid=>message.from.id]
    	if user==nil
    		bot.api.send_message(chat_id: message.from.id, text: "Аккаунт не авторизован, бота надо подключать по ссылке из профиля движка https://sqe.mlnn.ru/profile")
    		next
    	end
      	game=user.team.nil? ? nil :  Game[user.team.active_game]
      	if !user.team_adopt || game.nil?
      		bot.api.send_message(chat_id: message.from.id, text: "Нет игры") 
      		next
      	end
      	case game.state(user)
     	 when :wait
        	bot.api.send_message(chat_id: message.from.id, text: "Игра еще не началась") 
      		next
	      when :ingame
	        if user.team.curent_levels.empty?
	          bot.api.send_message(chat_id: message.from.id, text: "Нет уровней") 
      		  next
	        end
	      when :intest,:ingame
	        if user.team.curent_levels.empty?
	          bot.api.send_message(chat_id: message.from.id, text: "Нет уровней") 
      		  next
	        end


	      when :start
	        game.start_game(user)
	      when :closed
	          bot.api.send_message(chat_id: message.from.id, text: "Игра закрыта") 
      		  next
	      when :finish
	          bot.api.send_message(chat_id: message.from.id, text: "Игра все") 
      		  next
	      when :end
	          bot.api.send_message(chat_id: message.from.id, text: "Игра кончилась") 
      		  next
	      else
	          bot.api.send_message(chat_id: message.from.id, text: "хз чё происходит, походу баг") 
      		  next
	        
	    end
    	if !user.game_play? 
      		bot.api.send_message(chat_id: message.from.id, text: "Нет игры") 
      		next
      	end 
      
   
      	logger.info game
      	game.process_state(user,ts)
      	lvl=user.team.curent_levels.first
      	if lvl.nil?
      		bot.api.send_message(chat_id: message.from.id, text: "Нет уровней") 
      		next
      	end
      	level_id=lvl.level_id #todo make levele select

      	level_status=user.team.get_level(level_id)
      	if level_status.nil?
      		bot.api.send_message(chat_id: message.from.id, text: "нет доступа e->l.s.n?") 
      		next
      	end 
      	
      logger.info level_status
      data= UnicodeUtils.downcase(message.text.to_s).strip.gsub(/\s/,'')
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
      r[:ts]= resp[:log].nil? ?  resp[:ts].strftime("%H:%M:%S.%L") : resp[:log][:ts].strftime("%H:%M:%S.%L")
      r[:user]=resp[:log].nil? ? user.title : User[resp[:log][:user_id]].title
      r[:input]=data
      logger.info r
      if (r[:valid] && r[:type] == :spoiler) 
                    bot.api.send_message(chat_id: message.from.id, text: "\u2705 Ответ принят \u2705",reply_to_message_id:message.message_id)
                    # setTimeout(show_lvl, 1000)
      elsif !r[:valid] && r[:type] == :spoiler
                    bot.api.send_message(chat_id: message.from.id, text: "\u274C Ответ не принят \u274C",reply_to_message_id:message.message_id)
      elsif r[:type] == :code || r[:type] == :code_dup
                   str= code_status(r)
                   bot.api.send_message(chat_id: message.from.id, text: str,parse_mode:'HTML',reply_to_message_id:message.message_id)
      end

      game.process_state(user,ts)




    end
  end
rescue  Exception => e
  logger.info e.message
  sleep 1
end
end