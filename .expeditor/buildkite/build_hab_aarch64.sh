#!/usr/bin/env bash

# Builds the aarch64-linux chef-cli habitat package.
# Expeditor's built-in habitat/build pipeline does not support aarch64 targets,
# so this script handles the build as part of the hab_aarch64/build pipeline.

set -euo pipefail

export HAB_ORIGIN='chef'
export PLAN='chef-cli'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"

echo "--- :git: Checking for git"
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Installing Git..."
  sudo apt-get update -yq && sudo apt-get install -yq git
else
  echo "Git is already installed."
  git --version
fi

echo "--- :git: Adding safe directory exception"
git config --global --add safe.directory /workdir

echo "--- :linux: Installing Habitat"
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash

echo "--- :key: Downloading origin keys"
hab origin key download "$HAB_ORIGIN"
hab origin key download "$HAB_ORIGIN" --secret

echo "--- :construction: Building $PLAN aarch64-linux package"
hab pkg build . --refresh-channel base-2025

project_root="$(pwd)"
source "${project_root}/results/last_build.env" || { echo "ERROR: unable to determine build details"; exit 1; }

echo "--- :package: Uploading artifact to Buildkite"
cd "${project_root}/results"
buildkite-agent artifact upload "$pkg_artifact" || { echo "ERROR: unable to upload artifact"; exit 1; }

echo "--- Setting CHEF_CLI_HAB_ARTIFACT_LINUX_AARCH64 metadata for buildkite agent"
buildkite-agent meta-data set "CHEF_CLI_HAB_ARTIFACT_LINUX_AARCH64" "$pkg_artifact"
