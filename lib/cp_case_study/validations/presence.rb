# frozen_string_literal: true

module CpCaseStudy
  module Validations
    # Presence Validation
    class Presence < Validation
      private

      def valid?(value)
        !value.nil? && !value.to_s.strip.empty?
      end

      def message
        "can't be blank"
      end
    end
  end
end
