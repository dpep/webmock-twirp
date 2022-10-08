WebMock::Twirp
======
Twirp support for [WebMock](https://github.com/bblimke/webmock).  All our favorite http request stubbing for Twirp RPCs - message and error serialization done automatically.


```ruby
require "webmock-twirp"

stub_twirp_request(MyTwirpClient, :optional_rpc_method)

stub_twirp_request(...).with(my_request_message: /^foo/)

# or use block mode
stub_twirp_request(...).with do |request|
  request # the Twirp request, aka. proto message, used to initiate the request
  request.my_request_message == "hello"
end


stub_twirp_request(...).and_return(return_message: "yo yo")
stub_twirp_request(...).and_return(404) # results in a Twirp::Error.not_found

# or use block mode
stub_twirp_request(...).and_return do |request|
  { response_message: "oh hi" } # will get properly packaged up automagically
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
