require "google/protobuf"
require "twirp"
require "webmock"
require "webmock/twirp/matchers"
require "webmock/twirp/refinements"
require "webmock/twirp/request_stub"
require "webmock/twirp/version"


module WebMock
  module Twirp
    extend self

    private

    module API
      def stub_twirp_request(...)
        WebMock::StubRegistry.instance.register_request_stub(
          WebMock::Twirp::RequestStub.new(...),
        )
      end

      # def a_twirp_request(uri)
      #   WebMock::RequestPattern.new(:post, uri)
      # end
    end
  end
end

# patch WebMock to export Twirp helpers
module WebMock
  module API
    include WebMock::Twirp::API
  end

  module Matchers
    include WebMock::Twirp::Matchers
  end
end

if $LOADED_FEATURES.find { |x| x =~ %r{/webmock/rspec.rb$} }
  # require "webmock/rspec" was already called, so load helpers

  RSpec.configure do |conf|
    conf.include WebMock::Twirp::API
    conf.include WebMock::Twirp::Matchers
  end
end
