# frozen_string_literal: true

RSpec.describe CpCaseStudy::Configuration do
  let(:presence) { CpCaseStudy::Validations::Presence.new }
  let(:normalize) { CpCaseStudy::Transforms::NormalizeEmail.new }

  describe "#initialize" do
    context "when invalid rule is provided" do
      it "raises ArgumentError for non-Rule objects" do
        expect { described_class.new(email: ["not a rule"]) }
          .to raise_error(ArgumentError, /Invalid Rule/)
      end
    end
  end

  describe "#fields" do
    it "returns configured field names" do
      config = described_class.new(email: [normalize], name: [presence])
      expect(config.fields).to contain_exactly(:email, :name)
    end
  end

  describe "#rules_for" do
    it "returns rules for a configured field" do
      config = described_class.new(email: [normalize, presence])
      expect(config.rules_for(:email)).to eq([normalize, presence])
    end

    it "wraps a single rule in an array" do
      config = described_class.new(email: presence)
      expect(config.rules_for(:email)).to eq([presence])
    end

    it "returns empty array for unconfigured fields" do
      config = described_class.new(email: [normalize])
      expect(config.rules_for(:name)).to eq([])
    end
  end
end
