# frozen_string_literal: true

module CpCaseStudy
  module Transforms
    # Normalize email transformer
    class NormalizeEmail < Transform
      def transform(value)
        value.to_s.strip.downcase
      end
    end
  end
end
