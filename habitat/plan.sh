export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"
pkg_name=chef-cli
pkg_origin=chef
ruby_pkg="core/ruby3_4"
pkg_deps=(${ruby_pkg} core/coreutils core/libarchive core/git)
pkg_build_deps=(
    core/make
    core/sed
    core/gcc
    )
pkg_bin_dirs=(bin)

do_setup_environment() {
  build_line 'Setting GEM_HOME="$pkg_prefix/vendor"'
  export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
}
do_prepare() {
  ln -sf "$(pkg_interpreter_for core/ruby3_4 bin/ruby)" "$(pkg_interpreter_for core/coreutils bin/env)"
}
pkg_version() {
  cat "$SRC_PATH/VERSION"
}
do_before() {
  update_pkg_version
}
do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}
do_build() {

    export GEM_HOME="$pkg_prefix/vendor"

    build_line "Setting GEM_PATH=$GEM_HOME"
    export GEM_PATH="$GEM_HOME"
    bundle config --local without integration deploy maintenance
    bundle config --local jobs 4
    bundle config --local retry 5
    bundle config --local silence_root_warning 1
    bundle install
    gem build chef-cli.gemspec
    gem install rspec-core -v '~> 3.12.3'
    ruby ./post-bundle-install.rb
}
do_install() {
   export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  gem install chef-cli-*.gem --no-document
  set_runtime_env "GEM_PATH" "${pkg_prefix}/vendor"
  wrap_ruby_bin
  rm -rf $GEM_PATH/cache/
  rm -rf $GEM_PATH/bundler
  rm -rf $GEM_PATH/doc
}
wrap_ruby_bin() {
  local bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/chef-cli-${pkg_version}/bin/chef-cli"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e

# Set binary path that allows InSpec to use non-Hab pkg binaries
# Include Ruby bin directory so chef-cli exec can find gem, etc.
export PATH="$(pkg_path_for ${ruby_pkg})/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$pkg_prefix/vendor/bin:\$PATH"

# Set Ruby paths defined from 'do_setup_environment()'
  export GEM_HOME="$pkg_prefix/vendor"
  export GEM_PATH="$GEM_PATH"

exec $(pkg_path_for ${ruby_pkg})/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}


do_strip() {
  return 0
}