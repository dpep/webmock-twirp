describe RSpec do
  let(:twirp_helpers) do
    WebMock::Twirp::API.instance_methods + WebMock::Twirp::Matchers.instance_methods
  end
  let(:webmock_helpers) do
    WebMock::API.instance_methods + WebMock::Matchers.instance_methods
  end

  context "when webmock/rspec has been loaded" do
    it { expect($LOADED_FEATURES).to include(%r{/webmock/rspec.rb$}) }

    it "has loaded all Twirp helpers into RSpec" do
      twirp_helpers.each do |fn|
        expect(self).to respond_to(fn)
      end
    end
  end

  it "added the Twirp helpers into WebMock" do
    expect(webmock_helpers).to include(*twirp_helpers)
  end
end
