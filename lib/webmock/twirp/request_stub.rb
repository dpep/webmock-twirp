module WebMock
  module Twirp
    class RequestStub < WebMock::RequestStub
      def initialize(client_or_service, rpc_name)
        klass = client_or_service.is_a?(Class) ? client_or_service : client_or_service.class

        unless klass < ::Twirp::Client || klass < ::Twirp::Server
          raise TypeError, "expected Twirp Client or Service, found: #{client_or_service}"
        end

        @rpc_info = klass.rpcs.values.find do |x|
          x[:rpc_method] == rpc_name || x[:ruby_method] == rpc_name
        end

        raise ArgumentError, "invalid rpc method: #{rpc_name}" unless @rpc_info

        uri = "/#{klass.service_full_name}/#{@rpc_info[:rpc_method]}"

        super(:post, /#{uri}$/)
      end

      def with(request = nil, **attrs, &block)
        unless request.nil? || attrs.empty?
          raise ArgumentError, "specify request or attrs, but not both"
        end

        input_class = @rpc_info[:input_class]

        request_matcher = if request
          unless request.is_a?(input_class)
            raise TypeError, "Expected request to be type #{input_class}, found: #{request}"
          end

          { body: request.to_proto }
        end

        decoder = ->(http_request) do
          matched = true
          decoded_request = input_class.decode(http_request.body)

          if attrs.any?
            attr_matcher = Matchers::HashIncludingMatcher.new(**attrs)
            attr_hash = WebMock::Util::HashKeysStringifier.stringify_keys!(decoded_request.to_h, deep: true)

            matched &= attr_matcher === attr_hash
          end

          if block
            matched &= block.call(decoded_request)
          end

          matched
        end if attrs.any? || block_given?

        super(request_matcher || {}, &decoder)
      end

      def to_return(*responses, &block)
        unless responses.empty? || block.nil?
          raise ArgumentError, "specify responses or block, but not both"
        end

        # if no args, provide default response
        responses << nil if responses.empty? && block.nil?

        response_hashes = responses.map do |response|
          resp = generate_http_response(response)
        end

        input_class = @rpc_info[:input_class]
        decoder = ->(request) do
          res = block.call(input_class.decode(request.body))
          generate_http_response(res)
        end if block_given?

        super(*response_hashes, &decoder)
      end

      def to_return_json(*)
        raise NotImplementedError
      end

      private

      def generate_http_response(obj)
        res = case obj
        when nil
          @rpc_info[:output_class].new
        when Hash
          @rpc_info[:output_class].new(**obj)
        when Google::Protobuf::MessageExts, ::Twirp::Error
          obj
        when Symbol
          if ::Twirp::Error.valid_code?(obj)
            ::Twirp::Error.new(obj, obj)
          else
            raise ArgumentError, "invalid error code: #{obj}"
          end
        when Integer
          if code = ::Twirp::ERROR_CODES_TO_HTTP_STATUS.key(obj)
            ::Twirp::Error.new(code, code)
          else
            raise ArgumentError, "invalid error code: #{obj}"
          end
        else
          raise NotImplementedError
        end

        if res.is_a?(Google::Protobuf::MessageExts)
          {
            status: 200,
            headers: { "Content-Type" => ::Twirp::Encoding::PROTO },
            body: res.to_proto,
          }
        else # Twirp::Error
          {
            status: ::Twirp::ERROR_CODES_TO_HTTP_STATUS[res.code],
            headers: { "Content-Type" => ::Twirp::Encoding::JSON },
            body: ::Twirp::Encoding.encode_json(res.to_h),
          }
        end
      end
    end
  end
end
