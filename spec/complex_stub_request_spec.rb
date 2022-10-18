describe "stub_twirp_request" do
  define_example_method :stub_fail, stub_fail: true
  define_example_method :fstub_fail, stub_fail: true, focus: true

  let(:client) { ComplexClient.new("http://localhost/twirp") }
  let(:message) do
    ComplexMessage.new(
      msg: EchoRequest.new(msg: "woof"),
      uid: 123,
      date: date,
    )
  end
  let(:date) { { month: 10, day: 16 } }

  def rpc
    @rpc ||= client.echo(message)
  end

  after do |example|
    if example.metadata[:stub_fail]
      expect { rpc }.to raise_error(WebMock::NetConnectNotAllowedError)
    else
      rpc
    end
  end

  it "stubs twirp requests" do
    stub_twirp_request
  end

  it { stub_twirp_request.with(message) }

  it { stub_twirp_request.with(msg: anything) }
  it { stub_twirp_request.with(msg: { msg: "woof" }) }
  it { stub_twirp_request.with(msg: { msg: /^w/ }) }

  it { stub_twirp_request.with(uid: 123) }
  it { stub_twirp_request.with(uid: Integer) }

  it { stub_twirp_request.with(date: date) }
  it { stub_twirp_request.with(date: { month: 10, day: 16 }) }
  it { stub_twirp_request.with(date: include(month: 10)) }
  it { stub_twirp_request.with(date: include(month: 10, day: 16, year: 0)) }
  it { stub_twirp_request.with(date: { month: 10, day: 16, year: 0, type: :DATE_DEFAULT }) }
  it { stub_twirp_request.with(date: { month: 10, day: anything }) }
  it { stub_twirp_request.with(date: { month: 10, day: 16, year: Integer, type: anything }) }

  stub_fail do
    stub_twirp_request.with(date: { month: 10 })
  end

  stub_fail do
    stub_twirp_request.with(type: :ECHO_DOUBLE)
  end
end
