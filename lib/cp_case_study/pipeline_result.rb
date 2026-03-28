# frozen_string_literal: true

module CpCaseStudy
  PipelineResult = Struct.new(:rows, keyword_init: true) do
    def valid?
      rows.all?(&:valid?)
    end

    def errors
      rows.flat_map do |row|
        row.errors.map { |e| e.merge(row: row.row_number) }
      end
    end

    def valid_rows
      rows.select(&:valid?)
    end

    def invalid_rows
      rows.reject(&:valid?)
    end
  end
end
