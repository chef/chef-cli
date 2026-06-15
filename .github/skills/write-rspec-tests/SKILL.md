---
description: Step-by-step skill for writing RSpec unit tests for chef-cli following repository conventions
applyTo: "spec/**/*.rb"
---

# Skill: Write RSpec Unit Tests

## 1. Review Before Writing

```bash
cat spec/unit/command/install_spec.rb    # command spec example
ls spec/shared/                          # available shared contexts
cat spec/spec_helper.rb                  # RSpec + SimpleCov config
```

Key shared examples in `spec/shared/`:
- `"a command with a UI object"` — verifies `#ui` accessor (`spec/shared/command_with_ui_object.rb`)
- `"a file generator"` — for generator commands (`spec/shared/a_file_generator.rb`)

## 2. Spec File Structure

```ruby
#
# Copyright (c) 2019-2025 Progress Software Corporation and/or its subsidiaries
# or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
# ...
#

require "spec_helper"
require "shared/command_with_ui_object"
require "chef-cli/command/my_command"

describe ChefCLI::Command::MyCommand do
  it_behaves_like "a command with a UI object"

  let(:params) { [] }

  let(:command) do
    c = described_class.new
    c.apply_params!(params)
    c
  end

  # Default state
  it "disables debug by default" do
    expect(command.debug?).to be(false)
  end

  it "doesn't set a config path by default" do
    expect(command.config_path).to be_nil
  end

  # Option flags
  context "when debug mode is set" do
    let(:params) { ["-D"] }

    it "enables debug" do
      expect(command.debug?).to be(true)
    end
  end

  context "when an explicit config file path is given" do
    let(:params) { %w{-c ~/.chef/alternate_config.rb} }

    it "sets the config file path" do
      expect(command.config_path).to eq("~/.chef/alternate_config.rb")
    end
  end

  # Success path
  describe "#run" do
    let(:service) { instance_double(ChefCLI::PolicyfileServices::SomeService) }

    before do
      allow(described_class).to receive(:new).and_call_original
      allow(service).to receive(:run)
    end

    it "returns 0 on success" do
      allow(command).to receive(:service).and_return(service)
      expect(command.run(params)).to eq(0)
    end
  end

  # Error path
  context "when service raises an error" do
    it "prints the error and returns 1" do
      allow(command).to receive(:service).and_raise(ChefCLI::PolicyfileServiceError, "boom")
      expect(command.ui).to receive(:err)
      expect(command.run(params)).to eq(1)
    end
  end
end
```

## 3. Conventions

| Rule | Detail |
|------|--------|
| Always `require "spec_helper"` | Loads SimpleCov and RSpec config |
| Use `instance_double` | `verify_partial_doubles = true` is enforced |
| Use `let` (not `before`) | Lazy evaluation, clearer setup |
| Name contexts clearly | `"when X"` / `"with Y"` pattern |
| Test return codes | `0` = success, `1` = failure for command `run` |
| Avoid `allow_any_instance_of` | Prefer `instance_double` and explicit stubs |
| Order-independent | Tests must not rely on execution order |

## 4. Run and Verify

```bash
bundle exec rspec spec/unit/command/my_command_spec.rb --format documentation
bundle exec rspec spec/                # full suite
bundle exec rake style:chefstyle      # style check
open coverage/index.html              # SimpleCov — must be >80%
```
