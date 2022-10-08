describe "stub_twirp_request" do
  let(:client) { EchoClient.new("http://localhost/twirp") }
  let(:request) { EchoRequest.new(msg: "woof") }
  let(:response) { EchoResponse.new(msg: "woof") }
  let(:error) { Twirp::Error.new(:not_found, "Not There") }

  def rpc
    @rpc ||= client.echo(request)
  end

  after do
    if @stub
      rpc
      expect(@stub).to have_been_requested
    end
  end

  it "stubs twirp requests" do
    @stub = stub_twirp_request(client)
  end

  it "works with a twirp client class" do
    @stub = stub_twirp_request(client.class)
  end

  it "works with a twirp service" do
    @stub = stub_twirp_request(EchoService)
  end

  it "catches bogus input" do
    expect {
      stub_twirp_request(Object)
    }.to raise_error(TypeError, /expected Twirp Client or Service/)
  end

  context "when a specific rpc method is specified" do
    it "stubs a specific twirp request" do
      @stub = stub_twirp_request(client, :echo)
    end

    it "works with the rpc method name" do
      @stub = stub_twirp_request(client, :Echo)
    end

    it "works with the rpc method name in string form" do
      @stub = stub_twirp_request(client, "Echo")
    end

    it "does not stub different rpc method" do
      stub = stub_twirp_request(client, :double)

      expect { rpc }.to raise_error(WebMock::NetConnectNotAllowedError)
      expect(stub).not_to have_been_requested
    end
  end

  describe ".with" do
    it "matches attributes" do
      @stub = stub_twirp_request(client).with(msg: "woof")
    end

    it "matches an attribute regex" do
      @stub = stub_twirp_request(client).with(msg: /^wo+/)
    end

    it "matches proto messages" do
      @stub = stub_twirp_request(client).with(request)
    end

    it "supports block mode" do
      @stub = stub_twirp_request(client).with do |request|
        expect(request).to be_a(EchoRequest)
        expect(request.msg).to eq "woof"
      end
    end

    it "does not stub mismatches" do
      stub_twirp_request(client).with(msg: "rav")
      stub_twirp_request(client).with(msg: /rav/)
      stub_twirp_request(client).with(EchoRequest.new)
      stub_twirp_request(client).with { false }

      expect { rpc }.to raise_error(WebMock::NetConnectNotAllowedError)
    end

    it "does not permit a request and attrs" do
      expect {
        stub_twirp_request(client).with(request, **request.to_h)
      }.to raise_error(ArgumentError, /specify request or attrs/)
    end

    it "type checks the request param" do
      expect {
        stub_twirp_request(client).with(Object)
      }.to raise_error(TypeError, /to be Protobuf::MessageExts/)
    end
  end

  describe ".to_return" do
    it "defaults to the default response" do
      @stub = stub_twirp_request(client).to_return

      expect(rpc).to be_a(Twirp::ClientResp)
      expect(rpc.data).to be_a(EchoResponse)
    end

    it "supports attributes" do
      @stub = stub_twirp_request(client).to_return(msg: "rav")
      expect(rpc.data.msg).to eq "rav"
    end

    it "supports proto messages" do
      @stub = stub_twirp_request(client).to_return(response)
      expect(rpc.data.msg).to eq response.msg
    end

    it "supports Twirp errors" do
      @stub = stub_twirp_request(client).to_return(error)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be error.code
      expect(rpc.error.msg).to eq error.msg
    end

    it "supports Twirp error codes" do
      @stub = stub_twirp_request(client).to_return(:not_found)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    it "supports http error codes" do
      @stub = stub_twirp_request(client).to_return(404)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    context "with block mode" do
      it "passes in the Twirp request" do
        @stub = stub_twirp_request(client).to_return do |request|
          expect(request).to be_a(EchoRequest)
          nil
        end
      end

      it "defaults to the default response" do
        @stub = stub_twirp_request(client).to_return {}

        expect(rpc).to be_a(Twirp::ClientResp)
        expect(rpc.data).to be_a(EchoResponse)
      end

      it "supports attribute hashes" do
        @stub = stub_twirp_request(client).to_return do
          { msg: "boo" }
        end

        expect(rpc.data.msg).to eq "boo"
      end

      it "supports proto messages" do
        @stub = stub_twirp_request(client).to_return { response }
        expect(rpc.data.msg).to eq response.msg
      end

      it "supports Twirp errors" do
        @stub = stub_twirp_request(client).to_return { error }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be error.code
        expect(rpc.error.msg).to eq error.msg
      end

      it "supports Twirp error codes" do
        @stub = stub_twirp_request(client).to_return(:not_found)
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end

      it "supports http error codes" do
        @stub = stub_twirp_request(client).to_return { 404 }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end

      it "type checks the response" do
        stub_twirp_request(client).to_return { request }

        expect {
          rpc
        }.to raise_error(TypeError, /Expected type EchoResponse/)
      end
    end

    context "when used erroneously" do
      def check_for(*matchers)
        expect { rpc }.to raise_error(*matchers)
      end

      it "catches response type mismatches" do
        stub_twirp_request(client).to_return(request)
        check_for(TypeError, /Expected type EchoResponse/)
      end

      it "catches bogus error codes" do
        stub_twirp_request(client).to_return(:boom)
        check_for(ArgumentError, /invalid error code/)
      end

      it "catches bogus http status codes" do
        stub_twirp_request(client).to_return(200)
        check_for(ArgumentError, /invalid error code/)
      end

      it "catches bogus responses" do
        stub_twirp_request(client).to_return(Object)
        check_for(NotImplementedError)
      end

      it "does not permit a response and block" do
        expect {
          stub_twirp_request(client).to_return(response) { 500 }
        }.to raise_error(ArgumentError, /specify responses or block/)
      end
    end
  end

  describe ".to_return_json" do
    it "is unsupported" do
      expect {
        stub_twirp_request(client).to_return_json(response.to_h)
      }.to raise_error(NotImplementedError)
    end
  end
end
