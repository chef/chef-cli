---
description: Iterative develop-build-test-fix loop for chef-cli. Use when implementing features, fixing bugs, or improving packaging — guides through code, test, lint, build, validate cycles until green.
applyTo: "**/*.rb,habitat/**/*,spec/**/*,.expeditor/**/*,.buildkite/**/*"
---

# Skill: Development Loop

An iterative workflow that cycles through code → test → lint → build → validate until all checks pass.

## When to Use

- Implementing a new feature or fixing a bug
- Updating Habitat plans and needing build validation
- Preparing a branch for PR submission
- Any change requiring multiple rounds of fix-and-verify

## Loop Steps

### 1. Plan (once per task)

- Identify which files need changes (lib/, spec/, habitat/, .expeditor/).
- Determine the correct agent for each part:
  - **chef-command-expert** — new/modified CLI commands
  - **testing-agent** — RSpec tests (must achieve >80% coverage)
  - **ruby-reviewer** — code quality and security review
  - **habitat-agent** — Habitat plan updates and build validation
- Break work into atomic commits.

### 2. Implement

```bash
# Edit source files under lib/chef-cli/
# Edit/create specs under spec/unit/
```

### 3. Test (repeat until green)

```bash
# Run unit tests for the specific file
bundle exec rspec spec/unit/command/<command>_spec.rb --format documentation

# Run full test suite
bundle exec rspec spec/

# Check coverage
open coverage/index.html
```

**Gate:** Tests must pass and coverage must be >80%.

### 4. Lint (repeat until green)

```bash
bundle exec rake style:chefstyle
bundle exec rake style:cookstyle
```

Auto-fix safe offenses if needed:
```bash
bundle exec cookstyle --autocorrect-all
```

**Gate:** Zero lint errors.

### 5. Build (if Habitat plan changed)

```bash
# Syntax check
bash -n habitat/plan.sh
bash -n habitat/aarch64-darwin/plan.sh

# Build (linux)
hab pkg build .

# Build (macOS aarch64-darwin)
hab pkg build habitat/aarch64-darwin
```

**Gate:** Build produces a .hart file without errors.

### 6. Validate (if Habitat plan changed)

```bash
HART_FILE="$(ls -t results/*.hart | head -n1)"
sudo hab pkg install "$HART_FILE"
IDENT="$(basename "$HART_FILE" .hart | sed -E 's/-([0-9]{14})$//' | sed 's/-/\//')"
hab pkg exec "$IDENT" chef-cli --version
```

For macOS test script:
```bash
./habitat/tests/test.darwin.sh "$IDENT"
```

**Gate:** Runtime smoke test passes.

### 7. Review

Invoke `ruby-reviewer` agent to check:
- Security issues
- ChefCLI conventions compliance
- Code quality

### 8. Commit

```bash
git add <files>
git commit --signoff -m "<JIRA_ID>: description"
```

### 9. Repeat or Ship

- If any gate failed → go back to step 2 with the fix.
- If all gates pass → push and create PR.

```bash
git push origin <branch>
gh pr create --base main --head <branch> --title "<JIRA_ID>: summary" --body-file pr_description.html
```

## Quick Reference: Which Agent for What

| Task | Agent |
|------|-------|
| New/modified CLI command | `chef-command-expert` |
| Write/update RSpec tests | `testing-agent` |
| Ruby code review | `ruby-reviewer` |
| Habitat plan create/fix | `habitat-agent` |
| Habitat packaging strategy | `habitat-pkg-builder-expert` |

## Anti-Patterns

- Do NOT skip tests — every code change needs spec coverage
- Do NOT commit without DCO signoff (`--signoff`)
- Do NOT manually install Habitat build deps — declare them in the plan
- Do NOT hardcode product names — use `ChefCLI::Dist` constants
- Do NOT use `puts`/`$stderr` — use `ChefCLI::UI`
