# frozen_string_literal: true

RSpec.describe CpCaseStudy::Transforms::NormalizeEmail do
  subject(:transform) { described_class.new }

  it "downcases the value" do
    result = transform.call("USER@EXAMPLE.COM")
    expect(result.value).to eq("user@example.com")
  end

  it "strips whitespaces" do
    result = transform.call("  alice@example.com  ")
    expect(result.value).to eq("alice@example.com")
  end
end
