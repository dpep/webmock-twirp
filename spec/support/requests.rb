def capture_request
  res = nil

  WebMock.globally_stub_request do |request|
    res = request
  end

  yield

  res
rescue NoMethodError
  # Twirp client explodes due to invalid, nil response.  ignore
  res
ensure
  WebMock::StubRegistry.instance.global_stubs.clear
end
