require "twirp"

require_relative "echo_pb"

class EchoService < Twirp::Service
  service "Echo"
  rpc :Echo, EchoRequest, EchoResponse, :ruby_method => :echo
  rpc :Double, EchoRequest, EchoResponse, :ruby_method => :double
end

class EchoClient < Twirp::Client
  client_for EchoService
end

class EchoHandler
  def echo(req, env)
    { msg: req.msg }
  end

  def double(...)
    echo(...)
  end
end



class ComplexService < Twirp::Service
  package "example"
  service "Complex"

  rpc :Echo, ComplexMessage, ComplexMessage, :ruby_method => :echo
end

class ComplexClient < Twirp::Client
  client_for ComplexService
end

class ComplexHandler
  def echo(req, env)
    req
  end
end
