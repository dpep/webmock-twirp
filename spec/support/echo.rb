require "google/protobuf"
require "twirp"

pool = Google::Protobuf::DescriptorPool.new

pool.build do
  add_message "EchoRequest" do
    optional :msg, :string, 1
  end

  add_message "EchoResponse" do
    optional :msg, :string, 1
  end

  add_enum "DateType" do
    value :DATE_DEFAULT, 0
    value :DATE_BDAY, 1
  end

  add_message "DateMessage" do
    optional :type, :enum, 1, "DateType"
    optional :month, :int32, 2
    optional :day, :int32, 3
    optional :year, :int32, 4
  end

  add_message "ComplexMessage" do
    optional :msg, :message, 1, "EchoRequest"
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


DateType = pool.lookup("DateType").enummodule
DateMessage = pool.lookup("DateMessage").msgclass
ComplexMessage = pool.lookup("ComplexMessage").msgclass

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
