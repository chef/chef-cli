---
description: Step-by-step skill for debugging failures in the chef-cli gem — covering command errors, policyfile issues, and test failures
applyTo: "lib/chef-cli/**/*.rb,spec/**/*.rb"
---

# Skill: Debug Chef CLI

## 1. Reproduce the Failure

```bash
bundle exec chef-cli <command> [args] --debug
```

`--debug` enables stacktraces via `ChefCLI::Command::Base` and sets `Chef::Config[:log_level] = :debug`.

## 2. Run the Failing Spec

```bash
bundle exec rspec spec/unit/command/<command>_spec.rb --format documentation
bundle exec rspec spec/                         # full suite
```

## 3. Common Failure Patterns

### Command exits with code 1
- Check `run(params)` return value — `1` = error path.
- Look for `rescue` blocks in `lib/chef-cli/command/<command>.rb`.
- Check `ChefCLI::ServiceExceptions` for error classes and inspectors in `lib/chef-cli/service_exception_inspectors/`.

### OptionParser errors (`InvalidOption`, `MissingArgument`)
- Option defined in `Base` or in the command class via `Mixlib::CLI`.
- Verify `option` declarations match the flags being passed.

### Config file errors (`Chef::Exceptions::ConfigurationError`)
- Handled by `run_with_default_options` in `Base`.
- Check `ChefCLI::Configurable` is included and `config_path` is wired.

### Policyfile resolution failures
- Service objects live in `lib/chef-cli/policyfile_services/`.
- Exception details printed via `ChefCLI::ServiceExceptionInspectors`.
- Enable debug for full solver output.

### RSpec mock failures (`VerifyingDoubles`)
- `verify_partial_doubles = true` is enforced in `spec_helper.rb`.
- Use `instance_double(ClassName)` instead of plain `double`.

## 4. Style / Lint Errors

```bash
bundle exec rake style:chefstyle
bundle exec rake style:cookstyle
```

Autocorrect safe offenses:
```bash
bundle exec cookstyle --autocorrect-all
```

## 5. Coverage Gaps

```bash
bundle exec rspec spec/
open coverage/index.html    # view SimpleCov report
```

Target: **>80% coverage**. Identify uncovered branches and add focused RSpec examples.

## 6. Useful Entry Points

| File | Purpose |
|------|---------|
| `lib/chef-cli/cli.rb` | Top-level CLI dispatch |
| `lib/chef-cli/builtin_commands.rb` | Command registration |
| `lib/chef-cli/command/base.rb` | Shared options & error handling |
| `lib/chef-cli/exceptions.rb` | ChefCLI exception classes |
| `lib/chef-cli/service_exceptions.rb` | Service-level exception wrappers |
| `lib/chef-cli/ui.rb` | Output helpers (`msg`, `err`, `warn`) |
| `spec/spec_helper.rb` | RSpec + SimpleCov configuration |
