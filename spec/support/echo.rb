require "google/protobuf"
require "google/protobuf/descriptor_pb"
require "twirp"

# google-protobuf 4 removed the DescriptorPool#build DSL, so describe the
# protos with descriptor messages, which every version accepts
field = ->(name, number, type, type_name = nil, **opts) do
  Google::Protobuf::FieldDescriptorProto.new(
    name: name,
    number: number,
    label: :LABEL_OPTIONAL,
    type: :"TYPE_#{type.upcase}",
    type_name: type_name,
    **opts,
  )
end

message = ->(name, *fields, **opts) do
  Google::Protobuf::DescriptorProto.new(name: name, field: fields, **opts)
end

echo_proto = Google::Protobuf::FileDescriptorProto.new(
  name: "echo.proto",
  syntax: "proto3",
  enum_type: [
    Google::Protobuf::EnumDescriptorProto.new(
      name: "DateType",
      value: [
        Google::Protobuf::EnumValueDescriptorProto.new(name: "DATE_DEFAULT", number: 0),
        Google::Protobuf::EnumValueDescriptorProto.new(name: "DATE_BDAY", number: 1),
      ],
    ),
  ],
  message_type: [
    message.("EchoRequest", field.("msg", 1, :string)),
    message.("EchoResponse", field.("msg", 1, :string)),
    message.(
      "DateMessage",
      field.("type", 1, :enum, ".DateType"),
      field.("month", 2, :int32),
      field.("day", 3, :int32),
      field.("year", 4, :int32),
    ),
    message.(
      "ComplexMessage",
      field.("msg", 1, :message, ".EchoRequest"),
      field.("complex", 3, :bool),
      field.("date", 4, :message, ".DateMessage"),
      field.("uid", 5, :int32, oneof_index: 0),
      field.("uuid", 6, :string, oneof_index: 0),
      oneof_decl: [ Google::Protobuf::OneofDescriptorProto.new(name: "id") ],
    ),
  ],
)

pool = Google::Protobuf::DescriptorPool.new
pool.add_serialized_file(Google::Protobuf::FileDescriptorProto.encode(echo_proto))

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
