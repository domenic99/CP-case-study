# frozen_string_literal: true

module CpCaseStudy
  module Validations
    # Format validation
    class Format < Validation
      def initialize(pattern, message: "does not match expected format")
        super()
        @pattern = pattern
        @custom_message = message
      end

      private

      def valid?(value)
        @pattern.match?(value.to_s)
      end

      def message
        @custom_message
      end
    end
  end
end
