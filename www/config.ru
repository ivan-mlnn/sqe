require File.expand_path(File.dirname(__FILE__) + '/model/db')
require File.expand_path(File.dirname(__FILE__) + '/server')
require File.expand_path(File.dirname(__FILE__) + '/lib/team')
require File.expand_path(File.dirname(__FILE__) + '/lib/level')
require File.expand_path(File.dirname(__FILE__) + '/lib/game')

# require 'faye'
# require 'permessage_deflate'
# Faye::WebSocket.load_adapter('thin')
# use Faye::RackAdapter, :mount => '/faye', :timeout => 25 do |bayeux|
# bayeux.add_websocket_extension(PermessageDeflate)
# end

run SQE