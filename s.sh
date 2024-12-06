pkg_ident="sanghinitin/chef-cli/5.6.15/20241205082855"
version=$(hab pkg exec "${pkg_ident}" chef-cli -v)
echo $version
actual_version=$(echo "$version" | sed -E 's/.*version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
echo $actual_version
