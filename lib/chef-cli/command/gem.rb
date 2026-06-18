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
require "rubygems" unless defined?(Gem)
require "rubygems/gem_runner"
require "rubygems/exceptions"
require "fileutils" unless defined?(FileUtils)

module ChefCLI
  module Command
    # Forwards all commands to rubygems.
    class GemForwarder < ChefCLI::Command::Base
      banner "Usage: #{ChefCLI::Dist::EXEC} gem GEM_COMMANDS_AND_OPTIONS"

      def run(params)
        setup_gem_environment if habitat_gem_home_enabled?
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
