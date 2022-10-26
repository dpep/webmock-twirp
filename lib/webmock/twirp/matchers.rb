require "webmock/twirp/matchers/make_twirp_request"

module WebMock
  module Twirp
    module Matchers
      def make_twirp_request(...)
        MakeTwirpRequest.new(...)
      end

      alias_method :make_a_twirp_request, :make_twirp_request
    end
  end
end
