#!/usr/local/bin/ruby

require File.expand_path(File.dirname(__FILE__) + '/../model/db')
require 'logger'
include Model
logger = Logger.new(File.dirname(__FILE__) + '/../log/tick.log', 10, 1024000)
DB[:status].where(:end=>nil).each { |e|
  logger.info e
  # puts e
  game=Game[e[:game_id]]
  logger.info game
  team=Team[e[:team_id]]
  logger.info team
  # puts team.inspect
  game.process_state(nil,nil,nil,team)
}
