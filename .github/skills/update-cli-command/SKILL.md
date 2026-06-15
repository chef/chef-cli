---
description: Step-by-step skill for adding or modifying a built-in command in chef-cli
applyTo: "lib/chef-cli/command/**/*.rb,lib/chef-cli/builtin_commands.rb,spec/unit/command/**/*.rb"
---

# Skill: Add or Update a CLI Command

## 1. Find Existing Command Patterns

Read a similar command before writing any code:

```bash
# Example — read the install command
cat lib/chef-cli/command/install.rb
cat spec/unit/command/install_spec.rb
```

Key files to understand:
- `lib/chef-cli/command/base.rb` — shared options, error handling, `run_with_default_options`
- `lib/chef-cli/builtin_commands.rb` — command registration table
- `lib/chef-cli/ui.rb` — output helpers
- `lib/chef-cli/dist.rb` — product name constants

## 2. Create the Command File

Create `lib/chef-cli/command/my_command.rb`:

```ruby
#
# Copyright (c) 2019-2025 Progress Software Corporation and/or its subsidiaries
# or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
# ...
#

require_relative "base"
require_relative "../ui"
require_relative "../dist"

module ChefCLI
  module Command
    class MyCommand < Base

      banner(<<~E)
        Usage: #{ChefCLI::Dist::EXEC} my-command [options]

        Description of what this command does.

        Options:
      E

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new
      end

      def run(params = [])
        parse_options(params)
        # implementation
        0
      rescue ChefCLI::PolicyfileServiceError => e
        ui.err("Error: #{e.message}")
        1
      end
    end
  end
end
```

Rules:
- Always include the Apache 2.0 license header.
- Use `ChefCLI::Dist::EXEC` (not hardcoded `"chef"`).
- Use `ui.msg` / `ui.err` / `ui.warn` — never `puts` or `$stderr`.
- Return `0` for success, `1` for failure.

## 3. Register the Command

Add to `lib/chef-cli/builtin_commands.rb`:

```ruby
c.builtin "my-command", :MyCommand, desc: "Short description shown in chef -h"
```

The constant name (`:MyCommand`) must match the class name. The require path is inferred automatically from the constant name.

## 4. Add RSpec Tests

Create `spec/unit/command/my_command_spec.rb`. See the `write-rspec-tests` skill for the full pattern.

Minimum coverage:
- Default option values
- Each explicit flag (e.g., `-D`, `-c CONFIG`)
- Success path (`run` returns `0`)
- Error path (`run` returns `1`, error message printed)

## 5. Validate

```bash
bundle exec rspec spec/unit/command/my_command_spec.rb --format documentation
bundle exec rake style:chefstyle
bundle exec rspec spec/                 # full suite — ensure nothing is broken
open coverage/index.html                # confirm >80% coverage
```
