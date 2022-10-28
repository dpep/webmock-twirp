using WebMock::Twirp::Refinements

module WebMock
  module Twirp
    module RequestSignature
      def twirp_client
        @twirp_client ||= begin
          service_full_name, rpc_name = uri.path.split("/").last(2)

          # find matching client
          client = ObjectSpace.each_object(::Twirp::Client.singleton_class).find do |obj|
            next unless obj < ::Twirp::Client && obj.name
            obj.service_full_name == service_full_name && obj.rpcs.key?(rpc_name)
          end
        end
      end

      def twirp_rpc
        @twirp_rpc ||= begin
          rpc_name = uri.path.split("/").last
          client = twirp_client.rpcs[rpc_name] if twirp_client
        end
      end

      def twirp_request
        twirp_rpc[:input_class].decode(body) if twirp_rpc
      end

      def to_s
        return super unless twirp_rpc

        uri = WebMock::Util::URI.strip_default_port_from_uri_string(self.uri.to_s)
        params = twirp_request.normalized_hash.map do |k, v|
          "#{k}: #{v.inspect}"
        end.join(", ")

        string = "#{twirp_client}(#{uri})"
        string << ".#{twirp_rpc[:ruby_method]}"
        string << "(#{params.empty? ? "{}" : params})"

        string
      end
    end
  end
end

module WebMock
  class RequestSignature
    def self.new(...)
      super(...).tap do |instance|
        instance.extend(WebMock::Twirp::RequestSignature) if instance.proto_headers?
      end
    end
  end
end
