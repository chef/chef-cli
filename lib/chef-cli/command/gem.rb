# Copyright:: (c) 2019-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "base"
require_relative "../dist"
require_relative "../licensing/base"
require "rubygems" unless defined?(Gem)
require "rubygems/gem_runner"
require "rubygems/exceptions"
require "fileutils" unless defined?(FileUtils)
require "uri" unless defined?(URI)

module ChefCLI
  module Command
    # Forwards all commands to rubygems.
    class GemForwarder < ChefCLI::Command::Base
      banner "Usage: #{ChefCLI::Dist::EXEC} gem GEM_COMMANDS_AND_OPTIONS"

      CHEF_GEM_SOURCE_HOST = "rubygems.chef.io".freeze
      RUBYGEMS_ORG_HOST = "rubygems.org".freeze

      # gem subcommands that fetch from remote sources and need the Chef source configured.
      PREMIUM_SOURCE_COMMANDS = %w{install i search s fetch update download}.freeze

      def run(params)
        setup_gem_environment if habitat_gem_home_enabled?
        ensure_chef_gem_source(params)
        retval = Gem::GemRunner.new.run(params.clone)
        retval.nil? || retval
      rescue Gem::SystemExitException => e
        exit(e.exit_code)
      end

      # Lazy solution: By automatically returning false, we force ChefCLI::Base to
      # call this class' run method, so that Gem::GemRunner can handle the -v flag
      # appropriately (showing the gem version, or installing a specific version
      # of a gem).
      def needs_version?(_params)
        false
      end

      private

      # Checks gem sources before any remote-fetching command and ensures the
      # Chef Premium RubyGem server is configured:
      #   - Chef source present with valid v1 credentials → proceed.
      #   - Non-standard source present (incl. file://) → assume airgap, warn and skip.
      #   - Only rubygems.org (or unauthenticated chef source) → obtain license key and run `gem sources --add`.
      def ensure_chef_gem_source(params)
        return unless premium_source_command?(params)
        return if chef_gem_source_configured?

        custom = non_standard_sources
        unless custom.empty?
          err("WARN: A custom gem source (#{custom.join(", ")}) is already configured; assuming an air-gapped environment.")
          err("WARN: The Chef Premium RubyGem source was not added. Premium extensions may be unavailable.")
          return
        end

        license_key = chef_license_key
        if license_key.nil? || license_key.empty?
          err("WARN: No valid Chef license key was found, so the Chef Premium RubyGem source was not configured.")
          err("WARN: You will not be able to access premium extensions. Run `#{ChefCLI::Dist::EXEC} license add` to configure a license.")
          return
        end

        add_chef_gem_source(license_key)
      end

      # Returns true when the first non-flag token is a remote-fetching subcommand.
      def premium_source_command?(params)
        command = params.find { |p| !p.to_s.start_with?("-") }
        PREMIUM_SOURCE_COMMANDS.include?(command)
      end

      # Returns true only when rubygems.chef.io is configured with valid v1 credentials.
      # A bare https://rubygems.chef.io entry (no user/password) is not considered configured.
      def chef_gem_source_configured?
        Gem.sources.any? do |source|
          uri = URI.parse(source.to_s)
          uri.host == CHEF_GEM_SOURCE_HOST && uri.user == "v1" && !uri.password.to_s.empty?
        rescue URI::InvalidURIError
          false
        end
      end

      # Returns sources that are neither rubygems.org nor rubygems.chef.io.
      # Sources whose URI has no host (e.g. file://) or cannot be parsed are
      # treated as non-standard so the code errs on the side of not modifying sources.
      def non_standard_sources
        Gem.sources.reject do |source|
          uri = URI.parse(source.to_s)
          [RUBYGEMS_ORG_HOST, CHEF_GEM_SOURCE_HOST].include?(uri.host)
        rescue URI::InvalidURIError
          false
        end
      end

      # Persists the Chef Premium RubyGem server via `gem sources --add` so the
      # configuration survives the current process.
      def add_chef_gem_source(license_key)
        source_url = "https://v1:#{license_key}@#{CHEF_GEM_SOURCE_HOST}"
        Gem::GemRunner.new.run(["sources", "--add", source_url])
      rescue Gem::SystemExitException => e
        err("WARN: Failed to add the Chef Premium RubyGem source (exit #{e.exit_code}).") unless e.exit_code == 0
      end

      # Fetches the first Chef license key from env, CLI args, or persisted storage.
      # Does not prompt the terminal — if no key is found nil is returned and the
      # caller warns the user to run `chef license add`.
      def chef_license_key
        keys = ChefLicensing.license_keys
        keys.is_a?(Array) ? keys.first : nil
      rescue StandardError
        nil
      end

      # Detects whether the user gem home feature is enabled.
      # This is set via CHEF_GEM_HOME_ENABLED in the Habitat plan's
      # do_setup_environment/Invoke-SetupEnvironment, or falls back to
      # habitat_install? detection.
      def habitat_gem_home_enabled?
        ENV["CHEF_GEM_HOME_ENABLED"] == "true" || habitat_install?
      end

      # Sets up GEM_HOME and GEM_PATH to use ~/.chef/ruby/<ruby_version>/gems
      # when running inside a Habitat-based environment. This ensures gems
      # persist across Workstation upgrades since the Habitat package path
      # changes on each upgrade.
      def setup_gem_environment
        gem_dir = habitat_user_gem_dir
        FileUtils.mkdir_p(gem_dir) unless Dir.exist?(gem_dir)

        ENV["GEM_HOME"] = gem_dir
        # Include existing GEM_PATH so vendor gems remain accessible
        existing_gem_path = ENV["GEM_PATH"]
        ENV["GEM_PATH"] = [gem_dir, existing_gem_path].reject { |p| p.nil? || p.empty? }.join(File::PATH_SEPARATOR)
        Gem.clear_paths
      end
    end
  end
end
