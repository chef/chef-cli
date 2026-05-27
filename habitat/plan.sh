export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"
pkg_name=chef-cli
pkg_origin=chef
ruby_pkg="core/ruby3_4"
pkg_deps=(${ruby_pkg} core/coreutils core/libarchive)
pkg_build_deps=(
    core/make
    core/sed
    core/gcc
    core/git
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

  # Copy NOTICE.TXT to the package directory
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
  ruby ./cleanup_lint_roller.rb

  build_line "** generating binstubs for chef-cli with precise version pins"
  "$(pkg_path_for $ruby_pkg)/bin/ruby" "${pkg_prefix}/vendor/bin/appbundler" . "$pkg_prefix/bin" chef-cli

  build_line "** generating binstub_patch.rb"
  cat > binstub_patch.rb <<'PATCH'
unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
  bin_path = __dir__
  vendor_path = File.expand_path(File.join(bin_path, "..", "vendor"))
  ENV["GEM_HOME"] = vendor_path
  ENV["GEM_PATH"] = [vendor_path, ENV["GEM_PATH"]].compact.join(File::PATH_SEPARATOR)
  ENV["PATH"] = [bin_path, File.join(vendor_path, "bin"), RbConfig::CONFIG["bindir"], ENV["PATH"]].compact.join(File::PATH_SEPARATOR)
end
PATCH

  build_line "** patching binstubs to allow running directly"
  for binstub in ${pkg_prefix}/bin/*; do
    sed -i "/require \"rubygems\"/r binstub_patch.rb" "$binstub"
  done

  fix_interpreter "${pkg_prefix}/bin/*" "$ruby_pkg" bin/ruby

  build_line "** creating wrapper for runtime environment"
  mkdir -p "$pkg_prefix/libexec"
  mv "$pkg_prefix/bin/chef-cli" "$pkg_prefix/libexec/chef-cli"
  cat <<EOF > "$pkg_prefix/bin/chef-cli"
#!$(pkg_path_for core/bash)/bin/bash
set -e

export PATH="$(pkg_path_for ${ruby_pkg})/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$pkg_prefix/vendor/bin:\$PATH"
export LD_LIBRARY_PATH="$(pkg_path_for core/libarchive)/lib:\$LD_LIBRARY_PATH"
export GEM_HOME="$pkg_prefix/vendor"
export GEM_PATH="$pkg_prefix/vendor"

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

do_after() {
  build_line "Removing .github directories from vendored gems..."
  find "$pkg_prefix/vendor/gems" -type d -name ".github" \
      | while read github_dir; do rm -rf "$github_dir"; done
}


do_strip() {
  return 0
}