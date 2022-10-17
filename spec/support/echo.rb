pool = Google::Protobuf::DescriptorPool.new

pool.build do
  add_message "EchoRequest" do
    optional :msg, :string, 1
  end

  add_message "EchoResponse" do
    optional :msg, :string, 1
  end

  add_message "DateMessage" do
    optional :month, :int32, 1
    optional :day, :int32, 2
    optional :year, :int32, 3
  end

  add_enum "EchoType" do
    value :ECHO_DEFAULT, 0
    value :ECHO_DOUBLE, 1
  end

  add_message "ComplexMessage" do
    optional :msg, :message, 1, "EchoRequest"
    optional :type, :enum, 2, "EchoType"
    optional :complex, :bool, 3
    optional :date, :message, 4, "DateMessage"

    oneof :id do
      optional :uid, :int32, 5
      optional :uuid, :string, 6
    end
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


DateMessage = pool.lookup("DateMessage").msgclass
EchoType = pool.lookup("EchoType").enummodule
ComplexMessage = pool.lookup("ComplexMessage").msgclass

class ComplexService < Twirp::Service
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
