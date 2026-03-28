# frozen_string_literal: true

module CpCaseStudy
  RowResult = Struct.new(:row_number, :data, :errors, keyword_init: true) do
    def valid?
      errors.empty?
    end
  end
end
