# frozen_string_literal: true

module CpCaseStudy
  # Base class for validation rules.
  class Validation < Rule
    def call(value)
      if valid?(value)
        Rule::Result.new(value: value)
      else
        Rule::Result.new(value: value, error: message)
      end
    end

    private

    def valid?(_value)
      raise NotImplementedError, "#{self.class}#valid? must be implemented"
    end

    def message
      raise NotImplementedError, "#{self.class}#message must be implemented"
    end
  end
end
