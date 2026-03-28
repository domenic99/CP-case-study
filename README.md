# CpCaseStudy

A configurable CSV processing pipeline with composable transform and validation rules. Process CSV records through an ordered chain of rules that transform field values or validate them, collecting all errors instead of stopping on the first.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "cp_case_study"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install cp_case_study
```

## Usage

### Basic Pipeline

Define a pipeline by mapping column names (as symbols) to an ordered list of rules. Rules run in sequence — each transform feeds its output to the next rule, and validations accumulate errors without halting the chain.

```ruby
require "cp_case_study"

config = CpCaseStudy::Configuration.new(
  email: [
    CpCaseStudy::Transforms::NormalizeEmail.new,
    CpCaseStudy::Validations::Presence.new,
    CpCaseStudy::Validations::Format.new(/.+@.+\..+/)
  ],
  name: [
    CpCaseStudy::Transforms::DefaultValue.new("Unknown"),
    CpCaseStudy::Validations::Presence.new
  ]
)

pipeline = CpCaseStudy::Pipeline.new(config)
result = pipeline.call("data.csv")
```

### Inspecting Results

```ruby
result.valid?        # => true if every row passed all validations
result.rows          # => array of RowResult structs
result.valid_rows    # => rows with no errors
result.invalid_rows  # => rows with at least one error
result.errors        # => [{ row: 2, field: :email, message: "can't be blank" }, ...]

row = result.rows.first
row.row_number       # => 1 (1-indexed)
row.data             # => { email: "alice@example.com", name: "Alice" }
row.errors           # => []
row.valid?           # => true
```

### Built-in Rules

**Transforms** modify field values:

| Class | Description |
|---|---|
| `Transforms::NormalizeEmail` | Strips whitespace and downcases |
| `Transforms::DefaultValue` | Replaces nil/blank values with a default |

**Validations** check field values and collect errors:

| Class | Description |
|---|---|
| `Validations::Presence` | Fails if nil, empty, or whitespace-only |
| `Validations::Format` | Fails if value doesn't match the given regex |

The `Format` validation accepts an optional custom message:

```ruby
CpCaseStudy::Validations::Format.new(/\A\d{3}-\d{4}\z/, message: "must be ###-#### format")
```

### Custom Rules

Any object that inherits from `CpCaseStudy::Rule` and responds to `#call(value)` returning a `CpCaseStudy::Result` works as a rule. Two convenience base classes reduce boilerplate:

**Custom transform** — override `#transform(value)`:

```ruby
class Titleize < CpCaseStudy::Transform
  def transform(value)
    value.to_s.split.map(&:capitalize).join(" ")
  end
end
```

**Custom validation** — override `#valid?(value)` and `#message`:

```ruby
class MinLength < CpCaseStudy::Validation
  def initialize(min)
    super()
    @min = min
  end

  private

  def valid?(value)
    value.to_s.length >= @min
  end

  def message
    "must be at least #{@min} characters"
  end
end
```

Use them like any built-in rule:

```ruby
config = CpCaseStudy::Configuration.new(
  name: [Titleize.new, MinLength.new(2)]
)
pipeline = CpCaseStudy::Pipeline.new(config)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
