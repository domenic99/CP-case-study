# frozen_string_literal: true

require "tempfile"

RSpec.describe CpCaseStudy::Pipeline do
  let(:configuration) do
    CpCaseStudy::Configuration.new(
      email: [
        CpCaseStudy::Transforms::NormalizeEmail.new,
        CpCaseStudy::Validations::Presence.new,
        CpCaseStudy::Validations::Format.new(/.+@.+\..+/)
      ],
      name: [
        CpCaseStudy::Validations::Presence.new
      ]
    )
  end

  let(:pipeline) { described_class.new(configuration) }

  let(:basic_csv) do
    <<~CSV
      email,name
      ALICE@EXAMPLE.COM,Alice
      ,Bob
      bad-email,
    CSV
  end

  describe "#call" do
    it "returns a PipelineResult" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result).to be_a(CpCaseStudy::PipelineResult)
      end
    end

    it "processes each row" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result.rows.size).to eq(3)
      end
    end

    it "assigns sequential row numbers starting at 1" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result.rows.map(&:row_number)).to eq([1, 2, 3])
      end
    end
  end

  describe "transforms" do
    it "applies transforms to field values" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result.rows[0].data[:email]).to eq("alice@example.com")
      end
    end

    it "transforms run before validations in the chain" do
      with_csv("email,name\n  VALID@EXAMPLE.COM  ,Test\n") do |path|
        result = pipeline.call(path)
        expect(result.rows[0].data[:email]).to eq("valid@example.com")
        expect(result.rows[0]).to be_valid
      end
    end
  end

  describe "validations" do
    it "collects errors for invalid fields" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        row2 = result.rows[1]
        expect(row2.errors.map { |e| e[:field] }).to include(:email)
      end
    end

    it "collects multiple errors for the same field" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        row2_email_errors = result.rows[1].errors.select { |e| e[:field] == :email }
        expect(row2_email_errors.size).to be >= 2
      end
    end

    it "marks rows with errors as invalid" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result.rows[1]).not_to be_valid
      end
    end

    it "marks rows without errors as valid" do
      with_csv(basic_csv) do |path|
        result = pipeline.call(path)
        expect(result.rows[0]).to be_valid
      end
    end
  end

  describe "unconfigured columns" do
    it "passes unconfigured columns through unchanged" do
      with_csv("email,name,age\nalice@example.com,Alice,30\n") do |path|
        result = pipeline.call(path)
        expect(result.rows[0].data[:age]).to eq("30")
      end
    end
  end

  describe "initialization" do
    it "raises ArgumentError when given a hash instead of Configuration" do
      expect { described_class.new(name: [CpCaseStudy::Validations::Presence.new]) }
        .to raise_error(ArgumentError, /expected a CpCaseStudy::Configuration/)
    end
  end

  describe "extensibility" do
    it "accepts a custom rule class" do
      upcase_rule = Class.new(CpCaseStudy::Transform) do
        def transform(value)
          value.to_s.upcase
        end
      end

      config = CpCaseStudy::Configuration.new(name: [upcase_rule.new])
      pipe = described_class.new(config)
      with_csv("name\nalice\n") do |path|
        result = pipe.call(path)
        expect(result.rows[0].data[:name]).to eq("ALICE")
      end
    end
  end

  describe "file extension validation" do
    it "raises ArgumentError for non-.csv file paths" do
      expect { pipeline.call("data.txt") }.to raise_error(ArgumentError, /not a \.csv file/)
    end

    it "raises ArgumentError for files with no extension" do
      expect { pipeline.call("data") }.to raise_error(ArgumentError, /not a \.csv file/)
    end

    it "accepts .CSV uppercase extension" do
      file = Tempfile.new(["test", ".CSV"])
      file.write("email,name\nalice@example.com,Alice\n")
      file.close
      result = pipeline.call(file.path)
      expect(result.rows.size).to eq(1)
      file.unlink
    end
  end

  describe "edge cases" do
    it "handles empty CSV with headers only" do
      with_csv("email,name\n") do |path|
        result = pipeline.call(path)
        expect(result.rows).to be_empty
        expect(result.valid?).to be true
      end
    end

    it "handles all-valid data" do
      with_csv("email,name\nalice@example.com,Alice\nbob@example.com,Bob\n") do |path|
        result = pipeline.call(path)
        expect(result.valid?).to be true
        expect(result.valid_rows.size).to eq(2)
      end
    end

    it "handles all-invalid data" do
      with_csv("email,name\n,\n,\n") do |path|
        result = pipeline.call(path)
        expect(result.valid?).to be false
        expect(result.invalid_rows.size).to eq(2)
      end
    end
  end

  def with_csv(content)
    file = Tempfile.new(["test", ".csv"])
    file.write(content)
    file.close
    yield file.path
  ensure
    file.unlink
  end
end
