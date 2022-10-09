pool = Google::Protobuf::DescriptorPool.new

pool.build do
  add_message "EchoRequest" do
    optional :msg, :string, 1
  end

  add_message "EchoResponse" do
    optional :msg, :string, 1
  end
end

EchoRequest = pool.lookup("EchoRequest").msgclass
EchoResponse = pool.lookup("EchoResponse").msgclass

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
