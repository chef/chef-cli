---
name: habitat-packaging
description: 'Build, install, and validate Habitat packages for chef-cli. Use for hab pkg build failures, .hart install flow, and runtime validation with hab pkg exec on linux/macOS/windows plans.'
argument-hint: 'Plan path or platform context (for example habitat/aarch64-darwin/plan.sh)'
user-invocable: true
---

# Habitat Packaging

## When to Use
- You need to create or update Habitat plans in habitat/.
- hab pkg build fails for linux, macOS aarch64-darwin, or windows packaging.
- You need a full packaging validation workflow from build to runtime execution.

## First Principles
- Always determine target platform first (linux, macOS aarch64-darwin, or windows).
- Create or update the correct plan file for that platform before running any build/install commands.
- Declare required toolchain/runtime dependencies in pkg_build_deps and pkg_deps.
- Do not manually install build dependency packages before plan authoring. Habitat resolves declared dependencies during hab pkg build.

## Repository Context
- This repository packages chef-cli, not chef-client or cookstyle.
- Prefer chef-cli plan behavior from habitat/plan.sh as the baseline.
- For macOS native gem builds, prefer core/clang when core/gcc is unavailable.

## Required Workflow Sequence
Run these steps in order from the current working directory:

1. Identify platform and target plan path:
  - linux: habitat/plan.sh
  - macOS aarch64-darwin: habitat/aarch64-darwin/plan.sh (if present for target flow)
  - windows: habitat/plan.ps1
2. Create or update the target plan first:
  - Ensure callbacks and path handling are correct for the chosen platform.
  - Add/adjust pkg_build_deps and pkg_deps in the plan.
  - Do not run manual hab pkg install for build dependencies.
3. Validate plan syntax:
  - bash -n <plan path> (for .sh plans)
  - powershell syntax validation for plan.ps1 when applicable
4. Build package:
  - BUILD_LOG="$(pwd)/hab-pkg-build-$(date +%Y%m%d-%H%M%S).log"
  - hab pkg build . 2>&1 | tee "$BUILD_LOG"
  - If build fails with a permission error, retry with sudo:
    - sudo hab pkg build . 2>&1 | tee "$BUILD_LOG"
5. Resolve latest .hart full path:
  - HART_FILE="$(cd results && pwd)/$(ls -t results/*.hart | head -n1 | xargs basename)"
6. Install built artifact using full path:
  - hab pkg install "$HART_FILE"
  - If install fails with a permission error, retry with sudo:
    - sudo hab pkg install "$HART_FILE"
7. Derive ident from artifact name:
  - IDENT="$(basename "$HART_FILE" .hart | sed -E 's/-([0-9]{14})$//' | sed 's/-/\//')"
8. Run runtime smoke test:
  - hab pkg exec "$IDENT" chef-cli --version
  - If exec fails with a permission error, retry with sudo:
    - sudo hab pkg exec "$IDENT" chef-cli --version

## Output Requirements
- Always show build output in the final response by including:
  - path to BUILD_LOG
  - key build lines (success/failure, generated .hart path, elapsed time)
- If sudo was required, explicitly state which command needed sudo and why.

## Plan Fix Checklist
1. Confirm target platform and plan path before editing.
1. Verify callback flow: do_before, do_unpack, do_prepare, do_build, do_install, do_after.
2. Ensure nested plan paths copy the correct source root.
3. Ensure do_build and do_install run from Habitat cache source directory.
4. Ensure package build deps and runtime deps are declared in plan and match platform toolchain availability.
5. Keep Ruby/Bundler operations isolated from host home paths when needed.

## Common Remediations
- Native extension failures:
  - add compiler toolchain deps in pkg_build_deps (for macOS usually core/clang)
  - export CC and CXX from pkg_path_for
- RubyGems permission errors touching host paths:
  - export HOME to a writable Habitat cache path
  - export GEM_SPEC_CACHE to a local writable path
  - use local gem install for built artifacts where appropriate
- Incorrect install behavior:
  - install .hart using full absolute path
  - run hab pkg exec against resolved ident for final verification

## Result Format
Return results with:
1. Root cause
2. File changes
3. Commands run and outcomes
4. Remaining risks
