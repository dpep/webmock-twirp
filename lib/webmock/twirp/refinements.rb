module WebMock
  module Twirp
    module Refinements
      refine Array do
        def snag(&block)
          find(&block)&.tap { |x| delete(x) }
        end
      end

      refine Google::Protobuf::MessageExts do
        def normalized_hash(symbolize_keys: true)
          JSON.parse(
            to_json(preserve_proto_fieldnames: true),
            symbolize_names: symbolize_keys,
          )
        end
      end
    end
  end
end
