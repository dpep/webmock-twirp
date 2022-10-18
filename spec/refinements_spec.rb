describe WebMock::Twirp::Refinements do
  using described_class

  describe "Array#snag" do
    let(:data) { [ 1, 2, 3 ] }

    it "finds and removes an element" do
      res = data.snag { |x| x % 2 == 0 }

      expect(res).to be 2
      expect(data).not_to include res
    end

    it "handles nil gracefully" do
      res = data.snag { false }
      expect(res).to be nil
    end
  end

  describe "MessageExt#normalized_hash?" do
    it "discards default values" do
      expect(EchoRequest.new.normalized_hash).to eq({})
    end

    it "discards values that match defaults" do
      expect(EchoRequest.new(msg: "").normalized_hash).to eq({})
    end

    it "returns only non-default attributes" do
      expect(EchoRequest.new(msg: "hi").normalized_hash).to eq(msg: "hi")
    end

    it "can stringify keys" do
      expect(
        EchoRequest.new(msg: "hi").normalized_hash(symbolize_keys: false)
      ).to eq("msg" => "hi")
    end

    context "with ComplexMessage" do
      it "discards default values" do
        expect(ComplexMessage.new.normalized_hash).to eq({})
      end

      it "returns only non-default attributes" do
        msg = ComplexMessage.new(
          msg: EchoRequest.new(msg: "woof"),
          uid: 123,
          date: DateMessage.new(month: 10, day: 17),
        )

        expect(msg.normalized_hash).to eq(
          msg: { msg: "woof" },
          uid: 123,
          date: { month: 10, day: 17 },
        )
      end

      it "returns empty hashes for all-default sub-messages" do
        msg = ComplexMessage.new(msg: EchoRequest.new)

        expect(msg.normalized_hash).to eq(msg: {})
      end

      it "handles enums properly" do
        msg = ComplexMessage.new(
          date: DateMessage.new(type: :DATE_BDAY),
        )

        expect(msg.normalized_hash).to eq(date: { type: :DATE_BDAY })

        expect(msg.normalized_hash(symbolize_keys: false)).to eq(
          "date" => { "type" => :DATE_BDAY },
        )
      end
    end
  end
end
