describe "stub_twirp_request" do
  define_example_method :stub_fail, stub_fail: true
  define_example_method :fstub_fail, stub_fail: true, focus: true

  let(:client) { ComplexClient.new("http://localhost/twirp") }
  let(:message) do
    ComplexMessage.new(
      msg: EchoRequest.new(msg: "woof"),
      uid: 123,
      date: { month: 10, day: 16 },
    )
  end

  def rpc
    @rpc ||= client.echo(message)
  end

  after do |example|
    if example.metadata[:stub_fail]
      expect { rpc }.to raise_error(WebMock::NetConnectNotAllowedError)
    else
      rpc
      expect(@stub).to have_been_requested if @stub
    end
  end

  it "stubs twirp requests" do
    stub_twirp_request
  end

  it { stub_twirp_request.with(message) }

  context "with RSpec::Matchers" do
    it { stub_twirp_request.with(date: { month: 10, day: 16 }) }
    it { stub_twirp_request.with(date: { month: 10, day: 16, year: 0 }) }
    it { stub_twirp_request.with(date: { month: 10, day: anything }) }
    it { stub_twirp_request.with(date: { month: 10, day: 16, year: anything }) }

    stub_fail do
      stub_twirp_request.with(date: { month: 10 })
    end
  end

  context "without RSpec::Matchers" do
    before { hide_const("RSpec::Matchers::BuiltIn::Include") }

    it { stub_twirp_request.with(date: { month: 10, day: 16 }) }
    it { stub_twirp_request.with(date: { month: 10, day: 16, year: 0 }) }

    stub_fail do
      stub_twirp_request.with(date: { month: 10, day: anything })
    end

    stub_fail do
      stub_twirp_request.with(date: { month: 10, day: 16, year: anything })
    end

    stub_fail do
      stub_twirp_request.with(date: { month: 10 })
    end
  end
end
