# frozen_string_literal: true

RSpec.describe CpCaseStudy::Transforms::DefaultValue do
  subject(:transformed_value) { described_class.new("default").call(value) }

  describe "#call" do
    context "when no value is provided" do
      let(:value) { nil }

      it "replaces nil with the default" do
        expect(transformed_value).to be_an_instance_of(CpCaseStudy::Rule::Result)
        expect(transformed_value.value).to eq("default")
      end
    end

    context "when value is provided" do
      let(:value) { "custom" }

      it "returns provided value" do
        expect(transformed_value).to be_an_instance_of(CpCaseStudy::Rule::Result)
        expect(transformed_value.value).to eq(value)
      end
    end
  end
end
