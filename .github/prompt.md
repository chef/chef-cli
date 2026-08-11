Read:
- .github/copilot-instructions.md
- .github/skills/update-cli-command/SKILL.md
- .github/skills/write-rspec-tests/SKILL.md
- .github/skills/debug-chef-cli/SKILL.md

Use agents as needed:
- chef-command-expert for command architecture and registration.
- testing-agent for RSpec coverage and test structure.
- ruby-reviewer for Ruby quality and style validation.

Then add or update a Chef CLI command following existing repository patterns.
Generate production code, unit tests, and any required documentation updates.

Validation steps:
- bundle exec rspec spec/
- bundle exec rake style:chefstyle
- bundle exec rake style:cookstyle