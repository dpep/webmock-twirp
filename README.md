WebMock::Twirp
======
Twirp support for [WebMock](https://github.com/bblimke/webmock).  All our favorite http request stubbing for Twirp RPCs - message and error serialization done automatically.

###  Install
```ruby
gem "webmock-twirp"
```

###  Example
```ruby
require "webmock/twirp"

it "stubs twirp calls" do 
  stub_twirp_request
  
  client.my_rpc_method(request)
end

it "matches calls from specific twirp clients and rpc methods" do
  stub_twirp_request(MyTwirpClient, :optional_rpc_method)
end

# match parameters
stub_twirp_request.with(my_request_message: /^foo/)

# or use block mode
stub_twirp_request.with do |request|
  request # the Twirp request, aka. proto message, used to initiate the request
  request.my_request_message == "hello"
end


# stub responses
stub_twirp_request.and_return(return_message: "yo yo")
stub_twirp_request.and_return(404) # results in a Twirp::Error.not_found

# or use block mode
stub_twirp_request.and_return do |request|
  { response_message: "oh hi" } # will get properly packaged up
end
```


## Usage

### .with
`stub_twirp_request.with` allows you to only stub requests which match specific attributes.  It accepts a hash or a `Google::Protobuf::MessageExts` instance.  The hash supports constants, regexes, and rspec matchers.

```ruby
stub_twirp_request.with(message: "hi")
stub_twirp_request.with(message: /^h/)
stub_twirp_request.with(message: include("i"))

expected_request = MyTwirpRequest.new(message: "hi")
stub_twirp_request.with(expected_request)
```


If you want even more control over the matching criteria, use the block mode.  A `Protobuf` instance is passed into the block with the request's parameters.

```ruby
stub_twirp_request.with do |request|
  request.message == "hi"
end
```


### .to_return
`stub_twirp_request.to_return` allows you to specify a response, or use a default response.  It can be a hash or `Protobuf` instance.  To return an error, specify an error code, http status, or `Twirp::Error`.

```ruby
stub_twirp_request.to_return # ie. `MyTwirpResponse.new`

stub_twirp_request.to_return(msg: "bye")

response = MyTwirpResponse.new(msg: "bye")
stub_twirp_request.to_return(response)

# errors
stub_twirp_request.to_return(:not_found)
stub_twirp_request.to_return(404)
stub_twirp_request.to_return(Twirp::Error.not_found("Nope"))
```

The block mode passes in the request Protobuf.
```ruby
stub_twirp_request.to_return do |request|
  if request.message == "hi"
    { msg: "bye" }
  else
    :not_found
  end
end
```


----
## Contributing

Yes please  :)

1. Fork it
1. Create your feature branch (`git checkout -b my-feature`)
1. Ensure the tests pass (`bundle exec rspec`)
1. Commit your changes (`git commit -am 'awesome new feature'`)
1. Push your branch (`git push origin my-feature`)
1. Create a Pull Request


----
![Gem](https://img.shields.io/gem/dt/webmock-twirp?style=plastic)
[![codecov](https://codecov.io/gh/dpep/webmock-twirp/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/webmock-twirp)
