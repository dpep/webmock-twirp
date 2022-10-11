describe RSpec do
  let(:twirp_helpers) { WebMock::Twirp::API.instance_methods }
  let(:webmock_helpers) { WebMock::API.instance_methods }

  context "when webmock/rspec has been loaded" do
    it { expect($LOADED_FEATURES).to include(%r{/webmock/rspec.rb}) }

    it "has loaded all Twirp helpers into RSpec" do
      twirp_helpers.each do |fn|
        expect(self).to respond_to(fn)
      end
    end

    it "has not loaded Twirp helpers into WebMock" do
      expect(webmock_helpers).not_to include(*twirp_helpers)
    end
  end

  context "when webmock/rspec has not been loaded" do
    before do
      # fake it
      $LOADED_FEATURES.delete_if { |x| x.end_with?("/webmock/rspec.rb") }
      load "webmock/twirp.rb" # reload
    end

    it "added the Twirp helpers into WebMock" do
      expect(webmock_helpers).to include(*twirp_helpers)
    end
  end
end
