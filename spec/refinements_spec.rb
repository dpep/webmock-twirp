describe WebMock::Twirp::Refinements do
  describe "Array#snag" do
    using described_class

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
end
