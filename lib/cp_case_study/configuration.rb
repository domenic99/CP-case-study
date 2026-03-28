# frozen_string_literal: true

module CpCaseStudy
  # class for Configuration
  class Configuration
    def initialize(**rules)
      validate!(rules)
      @rules = rules.transform_values { |v| Array(v) }
    end

    def fields
      @rules.keys
    end

    def rules_for(field)
      @rules.fetch(field, [])
    end

    private

    def validate!(rules)
      rules.each do |field, field_rules|
        Array(field_rules).each do |rule|
          raise ArgumentError, "Invalid Rule for #{field}" unless rule.is_a?(Rule)
        end
      end
    end
  end
end
