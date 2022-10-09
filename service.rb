#!/usr/bin/env ruby

require "google/protobuf"
require "rack"
require "twirp"
require "webrick"
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

server = WEBrick::HTTPServer.new(Port: 3000)

handler = EchoHandler.new
service = EchoService.new(handler)
path_prefix = "/twirp/" + service.full_name
server.mount path_prefix, Rack::Handler::WEBrick, service

server.start

# client = EchoClient.new("http://localhost:3000/twirp")
# resp = client.echo(msg: "World")
# puts resp.data
