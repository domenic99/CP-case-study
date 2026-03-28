# frozen_string_literal: true

RSpec.describe CpCaseStudy::Validations::Presence do
  subject(:validation) { described_class.new }

  context "with a present value" do
    it "returns a successful result" do
      result = validation.call("hello")
      expect(result.success?).to be true
    end

    it "preserves the original value" do
      result = validation.call("hello")
      expect(result.value).to eq("hello")
    end
  end

  context "with nil" do
    it "returns an error" do
      result = validation.call(nil)
      expect(result.success?).to be false
      expect(result.error).to eq("can't be blank")
    end

    it "preserves the nil value" do
      result = validation.call(nil)
      expect(result.value).to be_nil
    end
  end

  context "with an empty string" do
    it "returns an error" do
      result = validation.call("")
      expect(result.success?).to be false
      expect(result.error).to eq("can't be blank")
    end
  end

  context "with whitespace only" do
    it "returns an error" do
      result = validation.call("   ")
      expect(result.success?).to be false
      expect(result.error).to eq("can't be blank")
    end
  end
end
