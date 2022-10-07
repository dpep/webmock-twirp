describe "stub_twirp_request" do
  let(:client) { GoodbyeClient.new("http://localhost/twirp") }
  let(:request) { GoodbyeRequest.new(name: "Ale") }
  let(:response) { GoodbyeResponse.new(message: "response") }
  let(:error) { Twirp::Error.new(:not_found, "Not There") }

  def bye
    @bye ||= client.bye(request)
  end

  after do
    # WebMock::StubRegistry.instance.request_stubs.each do |stub|
    #   expect(stub).to have_been_requested
    # end

    if @stub
      bye
      expect(@stub).to have_been_requested
    end
  end

  it "stubs twirp requests" do
    @stub = stub_twirp_request(client, :bye)
  end

  describe ".with" do
    it "matches attributes" do
      @stub = stub_twirp_request(client, :bye).with(name: "Ale")
    end

    it "matches an attribute regex" do
      @stub = stub_twirp_request(client, :bye).with(name: /^A/)
    end

    it "matches proto messages" do
      @stub = stub_twirp_request(client, :bye).with(request)
    end

    it "supports block mode" do
      @stub = stub_twirp_request(client, :bye).with do |request|
        expect(request).to be_a(GoodbyeRequest)
        expect(request.name).to eq "Ale"
      end
    end

    it "does not catch mismatches" do
      stub_twirp_request(client, :bye).with(name: "Alex")
      stub_twirp_request(client, :bye).with(name: /Axe/)
      stub_twirp_request(client, :bye).with(GoodbyeRequest.new)
      stub_twirp_request(client, :bye).with { false }

      expect { bye }.to raise_error(WebMock::NetConnectNotAllowedError)
    end
  end

  describe ".to_return" do
    it "defaults to the default response" do
      @stub = stub_twirp_request(client, :bye).to_return

      expect(bye).to be_a(Twirp::ClientResp)
      expect(bye.data).to be_a(GoodbyeResponse)
    end

    it "supports attributes" do
      @stub = stub_twirp_request(client, :bye).to_return(message: "woot")
      expect(bye.data.message).to eq "woot"
    end

    it "supports proto messages" do
      @stub = stub_twirp_request(client, :bye).to_return(response)
      expect(bye.data.message).to eq "response"
    end

    it "supports Twirp errors" do
      @stub = stub_twirp_request(client, :bye).to_return(error)
      expect(bye.error).to be_a(Twirp::Error)
      expect(bye.error.code).to be error.code
      expect(bye.error.msg).to eq error.msg
    end

    it "supports Twirp error codes" do
      @stub = stub_twirp_request(client, :bye).to_return(:not_found)
      expect(bye.error).to be_a(Twirp::Error)
      expect(bye.error.code).to be :not_found
      expect(bye.error.msg).to eq "not_found"
    end

    it "supports http error codes" do
      @stub = stub_twirp_request(client, :bye).to_return(404)
      expect(bye.error).to be_a(Twirp::Error)
      expect(bye.error.code).to be :not_found
      expect(bye.error.msg).to eq "not_found"
    end

    context "with block mode" do
      it "passes in the Twirp request" do
        @stub = stub_twirp_request(client, :bye).to_return do |request|
          expect(request).to be_a(GoodbyeRequest)
          nil
        end
      end

      it "defaults to the default response" do
        @stub = stub_twirp_request(client, :bye).to_return {}

        expect(bye).to be_a(Twirp::ClientResp)
        expect(bye.data).to be_a(GoodbyeResponse)
      end

      it "supports attribute hashes" do
        @stub = stub_twirp_request(client, :bye).to_return do
          { message: "boo" }
        end

        expect(bye.data.message).to eq "boo"
      end

      it "supports proto messages" do
        @stub = stub_twirp_request(client, :bye).to_return { response }
        expect(bye.data.message).to eq "response"
      end

      it "supports Twirp errors" do
        @stub = stub_twirp_request(client, :bye).to_return { error }
        expect(bye.error).to be_a(Twirp::Error)
        expect(bye.error.code).to be error.code
        expect(bye.error.msg).to eq error.msg
      end

      it "supports Twirp error codes" do
        @stub = stub_twirp_request(client, :bye).to_return(:not_found)
        expect(bye.error).to be_a(Twirp::Error)
        expect(bye.error.code).to be :not_found
      end

      it "supports http error codes" do
        @stub = stub_twirp_request(client, :bye).to_return { 404 }
        expect(bye.error).to be_a(Twirp::Error)
        expect(bye.error.code).to be :not_found
      end
    end
  end

  # expect(a_twirp_request(/Bye/)).to have_been_made
end
