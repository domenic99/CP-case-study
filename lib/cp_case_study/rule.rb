# frozen_string_literal: true

module CpCaseStudy
  # Base class for rule
  class Rule
    Result = Struct.new(:value, :error, keyword_init: true) do
      def success?
        error.nil?
      end
    end

    def call
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end
  end
end
