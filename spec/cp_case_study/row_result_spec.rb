# frozen_string_literal: true

RSpec.describe CpCaseStudy::RowResult do
  describe "#valid?" do
    it "returns true when errors are empty" do
      row = described_class.new(row_number: 1, data: { name: "Alice" }, errors: [])
      expect(row.valid?).to be true
    end

    it "returns false when errors are present" do
      row = described_class.new(
        row_number: 1,
        data: { name: "" },
        errors: [{ field: :name, message: "can't be blank" }]
      )
      expect(row.valid?).to be false
    end
  end

  describe "#row_number" do
    it "stores the row number" do
      row = described_class.new(row_number: 5, data: {}, errors: [])
      expect(row.row_number).to eq(5)
    end
  end

  describe "#data" do
    it "stores the processed data hash" do
      data = { email: "a@b.com", name: "Bob" }
      row = described_class.new(row_number: 1, data: data, errors: [])
      expect(row.data).to eq(data)
    end
  end
end
