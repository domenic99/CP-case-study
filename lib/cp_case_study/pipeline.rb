# frozen_string_literal: true

require "csv"

module CpCaseStudy
  # class to run Pipeline for CSV file with defined configuration
  class Pipeline
    def initialize(configuration)
      unless configuration.is_a?(Configuration)
        raise ArgumentError, "expected a CpCaseStudy::Configuration, got #{configuration.class}"
      end

      @configuration = configuration
    end

    def call(path, **csv_options)
      path = path.to_s

      raise ArgumentError, "#{path} is not a .csv file" unless File.extname(path).downcase == ".csv"

      rows = []
      row_number = 0
      options = { headers: true, header_converters: :symbol, encoding: "bom|utf-8" }.merge(csv_options)

      CSV.foreach(path, **options) do |csv_row|
        row_number += 1
        rows << process_row(csv_row, row_number)
      end

      PipelineResult.new(rows: rows)
    end

    private

    def process_row(csv_row, row_number)
      data = csv_row.to_h
      errors = []

      @configuration.fields.each do |field|
        value = data[field]

        @configuration.rules_for(field).each do |rule|
          result = rule.call(value)
          value = result.value
          errors << { field: field, message: result.error } unless result.success?
        end

        data[field] = value
      end

      RowResult.new(row_number: row_number, data: data, errors: errors)
    end
  end
end
