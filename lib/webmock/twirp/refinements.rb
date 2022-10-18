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
          res = {}

          self.class.descriptor.each do |field|
            key = symbolize_keys ? field.name.to_sym : field.name
            value = field.get(self)

            if value.is_a?(Google::Protobuf::MessageExts)
              # recursively serialize sub-message
              value = value.normalized_hash(symbolize_keys: symbolize_keys)
            end

            res[key] = value unless field.default == value
          end

          res
        end
      end
    end
  end
end
