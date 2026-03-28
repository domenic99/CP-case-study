# frozen_string_literal: true

module CpCaseStudy
  # Base class for transform rules.
  class Transform < Rule
    def call(value)
      Rule::Result.new(value: transform(value))
    end

    private

    def transform(_value)
      raise NotImplementedError, "#{self.class}#transform must be implemented"
    end
  end
end
