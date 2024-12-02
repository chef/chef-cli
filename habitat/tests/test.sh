
set -euo pipefail


project_root="$(git rev-parse --show-toplevel)"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

[[ -n "$pkg_ident" ]] || error 'no hab package identity provided'

package_version=$(awk -F  '{print $4}' <<<"$pkg_ident")

cd "${project_root}"

echo "--- :mag_right: Testing ${pkg_ident} executables"
actual_version=$(hab pkg exec "${pkg_ident}" chef-cli -v | sed -E 's/.*Version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
[[ "$package_version" = "$actual_version" ]] || error "chef-cli is not the expected version. Expected '$package_version', got '$actual_version'"

echo "--- :Running rake"
hab pkg exec "${pkg_ident}" rake unit
