# frozen_string_literal: true

RSpec.describe CpCaseStudy::PipelineResult do
  let(:valid_row) do
    CpCaseStudy::RowResult.new(row_number: 1, data: { name: "Alice" }, errors: [])
  end

  let(:invalid_row) do
    CpCaseStudy::RowResult.new(
      row_number: 2,
      data: { name: "" },
      errors: [{ field: :name, message: "can't be blank" }]
    )
  end

  describe "#valid?" do
    it "returns true when all rows are valid" do
      result = described_class.new(rows: [valid_row])
      expect(result.valid?).to be true
    end

    it "returns false when any row is invalid" do
      result = described_class.new(rows: [valid_row, invalid_row])
      expect(result.valid?).to be false
    end

    it "returns true for empty rows" do
      result = described_class.new(rows: [])
      expect(result.valid?).to be true
    end
  end

  describe "#errors" do
    it "returns empty array when no errors" do
      result = described_class.new(rows: [valid_row])
      expect(result.errors).to be_empty
    end

    it "collects errors from all rows with row numbers" do
      result = described_class.new(rows: [valid_row, invalid_row])
      expect(result.errors).to eq([{ row: 2, field: :name, message: "can't be blank" }])
    end
  end

  describe "#valid_rows" do
    it "returns only rows with no errors" do
      result = described_class.new(rows: [valid_row, invalid_row])
      expect(result.valid_rows).to eq([valid_row])
    end
  end

  describe "#invalid_rows" do
    it "returns only rows with errors" do
      result = described_class.new(rows: [valid_row, invalid_row])
      expect(result.invalid_rows).to eq([invalid_row])
    end
  end
end
