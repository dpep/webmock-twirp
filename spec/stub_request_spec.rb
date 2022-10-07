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
    @stub = stub_twirp_request(client, :echo)
  end

  describe ".with" do
    it "matches attributes" do
      @stub = stub_twirp_request(client, :echo).with(msg: "woof")
    end

    it "matches an attribute regex" do
      @stub = stub_twirp_request(client, :echo).with(msg: /^wo+/)
    end

    it "matches proto messages" do
      @stub = stub_twirp_request(client, :echo).with(request)
    end

    it "supports block mode" do
      @stub = stub_twirp_request(client, :echo).with do |request|
        expect(request).to be_a(EchoRequest)
        expect(request.msg).to eq "woof"
      end
    end

    it "does not catch mismatches" do
      stub_twirp_request(client, :echo).with(msg: "rav")
      stub_twirp_request(client, :echo).with(msg: /rav/)
      stub_twirp_request(client, :echo).with(EchoRequest.new)
      stub_twirp_request(client, :echo).with { false }

      expect { rpc }.to raise_error(WebMock::NetConnectNotAllowedError)
    end
  end

  describe ".to_return" do
    it "defaults to the default response" do
      @stub = stub_twirp_request(client, :echo).to_return

      expect(rpc).to be_a(Twirp::ClientResp)
      expect(rpc.data).to be_a(EchoResponse)
    end

    it "supports attributes" do
      @stub = stub_twirp_request(client, :echo).to_return(msg: "rav")
      expect(rpc.data.msg).to eq "rav"
    end

    it "supports proto messages" do
      @stub = stub_twirp_request(client, :echo).to_return(response)
      expect(rpc.data.msg).to eq response.msg
    end

    it "supports Twirp errors" do
      @stub = stub_twirp_request(client, :echo).to_return(error)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be error.code
      expect(rpc.error.msg).to eq error.msg
    end

    it "supports Twirp error codes" do
      @stub = stub_twirp_request(client, :echo).to_return(:not_found)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    it "supports http error codes" do
      @stub = stub_twirp_request(client, :echo).to_return(404)
      expect(rpc.error).to be_a(Twirp::Error)
      expect(rpc.error.code).to be :not_found
      expect(rpc.error.msg).to eq "not_found"
    end

    context "with block mode" do
      it "passes in the Twirp request" do
        @stub = stub_twirp_request(client, :echo).to_return do |request|
          expect(request).to be_a(EchoRequest)
          nil
        end
      end

      it "defaults to the default response" do
        @stub = stub_twirp_request(client, :echo).to_return {}

        expect(rpc).to be_a(Twirp::ClientResp)
        expect(rpc.data).to be_a(EchoResponse)
      end

      it "supports attribute hashes" do
        @stub = stub_twirp_request(client, :echo).to_return do
          { msg: "boo" }
        end

        expect(rpc.data.msg).to eq "boo"
      end

      it "supports proto messages" do
        @stub = stub_twirp_request(client, :echo).to_return { response }
        expect(rpc.data.msg).to eq response.msg
      end

      it "supports Twirp errors" do
        @stub = stub_twirp_request(client, :echo).to_return { error }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be error.code
        expect(rpc.error.msg).to eq error.msg
      end

      it "supports Twirp error codes" do
        @stub = stub_twirp_request(client, :echo).to_return(:not_found)
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end

      it "supports http error codes" do
        @stub = stub_twirp_request(client, :echo).to_return { 404 }
        expect(rpc.error).to be_a(Twirp::Error)
        expect(rpc.error.code).to be :not_found
      end
    end
  end
end
