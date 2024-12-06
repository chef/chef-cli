pkg_ident="sanghinitin/chef-cli/5.6.15/20241205082855"
version=$(hab pkg exec "${pkg_ident}" chef-cli -v)
echo $version
actual_version=$(echo "[2024-12-06T07:35:58+00:00] WARN: Please install an English UTF-8 locale for Chef Infra Client to use, falling back to C locale and disabling UTF-8 support. Chef CLI version: 5.6.15" | sed -E 's/.*version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
echo $actual_version
