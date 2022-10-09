module WebMock
  module Twirp
    module Refinements
      refine Array do
        def snag(&block)
          find(&block)&.tap { |x| delete(x) }
        end
      end
    end
  end
end
