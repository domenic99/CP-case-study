# frozen_string_literal: true

require_relative "cp_case_study/version"
require_relative "cp_case_study/row_result"
require_relative "cp_case_study/pipeline_result"
require_relative "cp_case_study/rule"
require_relative "cp_case_study/transform"
require_relative "cp_case_study/validation"
require_relative "cp_case_study/transforms/normalize_email"
require_relative "cp_case_study/transforms/default_value"
require_relative "cp_case_study/validations/presence"
require_relative "cp_case_study/validations/format"
require_relative "cp_case_study/configuration"
require_relative "cp_case_study/pipeline"

module CpCaseStudy
  class Error < StandardError; end
end
