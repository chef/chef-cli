export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"
pkg_name=chef-cli
pkg_origin=chef
ruby_pkg="core/ruby3_4"
pkg_deps=(${ruby_pkg} core/coreutils core/libarchive)
pkg_build_deps=(
  core/make
  core/gcc
  core/git
)
pkg_bin_dirs=(bin)

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"

  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"

  # Allow user-installed gems to persist across package upgrades.
  # The actual GEM_HOME/GEM_PATH will be resolved at runtime via the wrapper
  # script to include ~/.chef/ruby/<ruby_version>/gems.
  set_runtime_env CHEF_GEM_HOME_ENABLED "true"
}

do_prepare() {
  if [[ ! -f /usr/bin/env ]]; then
    ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
  fi
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
    bundle config unset with
    bundle config --local without integration deploy maintenance test development profile
    bundle config --local jobs 4
    bundle config --local retry 5
    bundle config --local silence_root_warning 1
    bundle install
    gem build chef-cli.gemspec
    gem install rspec-core -v '~> 3.12.3'
    ruby ./cleanup_gem_lockfiles.rb
    ruby ./post-bundle-install.rb
}

do_install() {

  # Copy NOTICE to the package directory
  if [[ -f "$PLAN_CONTEXT/../NOTICE" ]]; then
    build_line "Copying NOTICE to package directory"
    cp "$PLAN_CONTEXT/../NOTICE" "$pkg_prefix/"
  else
    build_line "Warning: NOTICE not found at $PLAN_CONTEXT/../NOTICE"
  fi

  export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  gem install chef-cli-*.gem --no-document
  ruby ./cleanup_gem_lockfiles.rb

  build_line "** fixing binstub shebangs"
  fix_interpreter "${pkg_prefix}/vendor/bin/*" "$ruby_pkg" bin/ruby

  build_line "** generating binstubs for chef-cli with precise version pins"
  "${pkg_prefix}/vendor/bin/appbundler" . "$pkg_prefix/bin" chef-cli

  build_line "** patching binstubs to allow running directly"
  for binstub in ${pkg_prefix}/bin/*; do
    sed -i "/require \"rubygems\"/r ${PLAN_CONTEXT}/../binstub_patch.rb" "$binstub"
  done

  build_line "** creating wrapper for runtime environment"
  mkdir -p "$pkg_prefix/libexec"
  mv "$pkg_prefix/bin/chef-cli" "$pkg_prefix/libexec/chef-cli"
  cat <<EOF > "$pkg_prefix/bin/chef-cli"
#!$(pkg_path_for core/bash)/bin/bash
set -e

# Determine Ruby version for user gem path
RUBY_ABI_VERSION=\$($(pkg_path_for ${ruby_pkg})/bin/ruby -e 'puts RbConfig::CONFIG["ruby_version"]')
USER_GEM_HOME="\${HOME}/.chef/ruby/\${RUBY_ABI_VERSION}/gems"

# Create user gem directory if it does not exist
mkdir -p "\${USER_GEM_HOME}"

export PATH="$(pkg_path_for ${ruby_pkg})/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:\${USER_GEM_HOME}/bin:$pkg_prefix/vendor/bin:\$PATH"
export LD_LIBRARY_PATH="$(pkg_path_for core/libarchive)/lib:\$LD_LIBRARY_PATH"
export GEM_HOME="\${USER_GEM_HOME}"
export GEM_PATH="\${USER_GEM_HOME}:$pkg_prefix/vendor"

exec $(pkg_path_for ${ruby_pkg})/bin/ruby $pkg_prefix/libexec/chef-cli "\$@"
EOF
  chmod -v 755 "$pkg_prefix/bin/chef-cli"

  rm -rf $GEM_PATH/cache/
  rm -rf $GEM_PATH/bundler
  rm -rf $GEM_PATH/doc
}


do_after() {
  build_line "Removing .github directories from vendored gems..."
  find "$pkg_prefix/vendor/gems" -type d -name ".github" \
      | while read github_dir; do rm -rf "$github_dir"; done
}


do_strip() {
  return 0
}

do_end() {
  if [[ "$(readlink /usr/bin/env)" = "$(pkg_interpreter_for core/coreutils bin/env)" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}
