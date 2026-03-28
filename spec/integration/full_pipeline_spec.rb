# frozen_string_literal: true

RSpec.describe "Full pipeline integration" do
  subject(:result) { pipeline.call(csv_path) }

  let(:csv_path) { File.expand_path("../fixtures/sample.csv", __dir__) }

  let(:configuration) do
    CpCaseStudy::Configuration.new(
      email: [
        CpCaseStudy::Transforms::NormalizeEmail.new,
        CpCaseStudy::Validations::Presence.new,
        CpCaseStudy::Validations::Format.new(/.+@.+\..+/)
      ],
      name: [
        CpCaseStudy::Transforms::DefaultValue.new("Unknown"),
        CpCaseStudy::Validations::Presence.new
      ],
      phone: [
        CpCaseStudy::Validations::Format.new(/\A\d{3}-\d{4}\z/, message: "must be ###-#### format")
      ]
    )
  end

  let(:pipeline) { CpCaseStudy::Pipeline.new(configuration) }

  describe "processing the sample CSV file from disk" do
    it "processes all 5 rows" do
      expect(result.rows.size).to eq(5)
    end

    it "identifies 3 valid and 2 invalid rows" do
      expect(result.valid_rows.size).to eq(3)
      expect(result.invalid_rows.size).to eq(2)
    end

    it "reports the overall result as invalid" do
      expect(result.valid?).to eq(false)
    end

    it "assigns sequential 1-indexed row numbers" do
      expect(result.rows.map(&:row_number)).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "row 1: alice@example.com, Alice, 555-1234 (all fields valid)" do
    subject(:row) { result.rows[0] }

    it "is valid" do
      expect(row).to be_valid
    end

    it "keeps values unchanged when they already conform" do
      expect(row.data).to eq(email: "alice@example.com", name: "Alice", phone: "555-1234")
    end
  end

  describe "row 2: BOB@EXAMPLE.COM with surrounding whitespace (transforms normalize)" do
    subject(:row) { result.rows[1] }

    it "is valid" do
      expect(row).to be_valid
    end

    it "normalizes email to lowercase and stripped" do
      expect(row.data[:email]).to eq("bob@example.com")
    end

    it "preserves other fields" do
      expect(row.data[:name]).to eq("Bob")
      expect(row.data[:phone]).to eq("555-5678")
    end
  end

  describe "row 3: missing email, valid name and phone" do
    subject(:row) { result.rows[2] }

    it "is invalid" do
      expect(row).not_to be_valid
    end

    it "collects both presence and format errors for email" do
      email_errors = row.errors.select { |e| e[:field] == :email }
      messages = email_errors.map { |e| e[:message] }
      expect(messages).to include("can't be blank")
      expect(messages).to include("does not match expected format")
    end

    it "has no errors on name or phone" do
      other_errors = row.errors.reject { |e| e[:field] == :email }
      expect(other_errors).to be_empty
    end
  end

  describe "row 4: invalid-email, blank name, bad phone (multiple field failures)" do
    subject(:row) { result.rows[3] }

    it "is invalid" do
      expect(row).not_to be_valid
    end

    it "fails email format validation" do
      email_msgs = row.errors.select { |e| e[:field] == :email }.map { |e| e[:message] }
      expect(email_msgs).to include("does not match expected format")
    end

    it "replaces the blank name with the default value" do
      expect(row.data[:name]).to eq("Unknown")
    end

    it "fails phone format with custom message" do
      phone_msgs = row.errors.select { |e| e[:field] == :phone }.map { |e| e[:message] }
      expect(phone_msgs).to include("must be ###-#### format")
    end
  end

  describe "row 5: valid email, whitespace-only name replaced by default, valid phone" do
    subject(:row) { result.rows[4] }

    it "is valid after transforms fix all fields" do
      expect(row).to be_valid
    end

    it "normalizes email" do
      expect(row.data[:email]).to eq("carol@example.com")
    end

    it "replaces whitespace-only name with the default" do
      expect(row.data[:name]).to eq("Unknown")
    end
  end

  describe "aggregated errors across all rows" do
    it "includes row number, field, and message in every error" do
      expect(result.errors).to all(include(:row, :field, :message))
    end

    it "contains errors from multiple rows" do
      row_numbers = result.errors.map { |e| e[:row] }.uniq
      expect(row_numbers.size).to be > 1
    end
  end

  describe "unconfigured columns pass through unchanged" do
    it "preserves phone values even though phone has rules" do
      expect(result.rows[0].data[:phone]).to eq("555-1234")
    end
  end

  describe "extensibility: custom rule class" do
    it "works with a user-defined transform in the pipeline" do
      titleize = Class.new(CpCaseStudy::Transform) do
        def transform(value)
          value.to_s.split.map(&:capitalize).join(" ")
        end
      end

      custom_config = CpCaseStudy::Configuration.new(
        name: [titleize.new, CpCaseStudy::Validations::Presence.new]
      )
      custom_pipeline = CpCaseStudy::Pipeline.new(custom_config)
      fixture = File.expand_path("../fixtures/extensibility.csv", __dir__)
      result = custom_pipeline.call(fixture)
      expect(result.rows[0].data[:name]).to eq("John Doe")
      expect(result.rows[0]).to be_valid
    end
  end
end
