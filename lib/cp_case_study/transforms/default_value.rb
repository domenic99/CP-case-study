# frozen_string_literal: true

module CpCaseStudy
  module Transforms
    # Default value transformer
    class DefaultValue < Transform
      def initialize(default)
        super()
        @default = default
      end

      def transform(value)
        blank?(value) ? @default : value
      end

      private

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
