# frozen_string_literal: true

RSpec.describe CpCaseStudy::Validations::Format do
  describe "with an email pattern" do
    subject(:validation) { described_class.new(/.+@.+\..+/) }

    it "passes for a valid email" do
      result = validation.call("user@example.com")
      expect(result.success?).to be true
      expect(result.value).to eq("user@example.com")
    end

    it "fails for invalid email" do
      result = validation.call("not-an-email")
      expect(result.success?).to be false
    end

    it "uses the default error message" do
      result = validation.call("bad")
      expect(result.error).to eq("does not match expected format")
    end
  end

  describe "with a custom message" do
    subject(:validation) do
      described_class.new(/\A\d{3}-\d{4}\z/, message: "must be a phone number")
    end

    it "fails with the custom message" do
      result = validation.call("abc")
      expect(result.success?).to be false
      expect(result.error).to eq("must be a phone number")
    end
  end
end
