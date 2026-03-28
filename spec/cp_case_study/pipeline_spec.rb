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
  let(:file) do
    file = Tempfile.new(["test", ".csv"])
    file.write(csv_content)
    file.close
    file
  end
  let(:csv_content) do
    <<~CSV
      email,name
      ALICE@EXAMPLE.COM,Alice
      ,Bob
      bad-email,
    CSV
  end

  after do
    file.unlink
  end

  describe "#initialization" do
    it "raises ArgumentError when given a hash instead of Configuration" do
      expect { described_class.new(name: [CpCaseStudy::Validations::Presence.new]) }
        .to raise_error(ArgumentError, /expected a CpCaseStudy::Configuration/)
    end
  end

  describe "#call" do
    it "returns a PipelineResult" do
      result = pipeline.call(file.path)
      expect(result).to be_a(CpCaseStudy::PipelineResult)
    end

    it "processes each row" do
      result = pipeline.call(file.path)
      expect(result.rows.size).to eq(3)
    end

    it "assigns sequential row numbers starting at 1" do
      result = pipeline.call(file.path)
      expect(result.rows.map(&:row_number)).to eq([1, 2, 3])
    end

    context "with value transform" do
      let(:csv_content) do
        "email,name\n  VALID@EXAMPLE.COM  ,Test\n"
      end

      it "applies transforms to field values" do
        result = pipeline.call(file.path)
        expect(result.rows[0].data[:email]).to eq("valid@example.com")
      end

      it "transforms run before validations in the chain" do
        result = pipeline.call(file.path)
        expect(result.rows[0].data[:email]).to eq("valid@example.com")
        expect(result.rows[0]).to be_valid
      end
    end

    context "with validations" do
      it "collects errors for invalid fields" do
        result = pipeline.call(file.path)
        row2 = result.rows[1]
        expect(row2.errors.map { |e| e[:field] }).to include(:email)
      end

      it "collects multiple errors for the same field" do
        result = pipeline.call(file.path)
        row2_email_errors = result.rows[1].errors.select { |e| e[:field] == :email }
        expect(row2_email_errors.size).to be >= 2
      end

      it "marks rows with errors as invalid" do
        result = pipeline.call(file.path)
        expect(result.rows[1]).not_to be_valid
      end

      it "marks rows without errors as valid" do
        result = pipeline.call(file.path)
        expect(result.rows[0]).to be_valid
      end
    end

    context "with unconfigured columns" do
      let(:csv_content) { "email,name,age\nalice@example.com,Alice,30\n" }

      it "passes unconfigured columns through unchanged" do
        result = pipeline.call(file.path)
        expect(result.rows[0].data[:age]).to eq("30")
      end
    end

    context "with custom rule" do
      let(:csv_content) { "name\nalice\n" }

      it "accepts a custom rule class" do
        upcase_rule = Class.new(CpCaseStudy::Transform) do
          def transform(value)
            value.to_s.upcase
          end
        end

        config = CpCaseStudy::Configuration.new(name: [upcase_rule.new])
        pipe = described_class.new(config)
        result = pipe.call(file.path)
        expect(result.rows[0].data[:name]).to eq("ALICE")
      end
    end

    context "with file extension validation" do
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

    context "with edge cases" do
      context "with empty CSV" do
        let(:csv_content) { "email,name\n" }

        it "handles empty CSV with headers only" do
          result = pipeline.call(file.path)
          expect(result.rows).to be_empty
          expect(result.valid?).to be true
        end
      end

      context "with all-valid data" do
        let(:csv_content) { "email,name\nalice@example.com,Alice\nbob@example.com,Bob\n" }

        it "handles all-valid data" do
          result = pipeline.call(file.path)
          expect(result.valid?).to be true
          expect(result.valid_rows.size).to eq(2)
        end
      end

      context "with all-invalid data" do
        let(:csv_content) { "email,name\n,\n,\n" }

        it "handles all-invalid data" do
          result = pipeline.call(file.path)
          expect(result.valid?).to be false
          expect(result.invalid_rows.size).to eq(2)
        end
      end
    end
  end
end
