#
# Copyright:: Chef Software Inc.
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
require_relative "../cookbook_omnifetch"
require_relative "../ui"
require_relative "../version"
require_relative "../dist"

module Mixlib
  autoload :ShellOut, "mixlib/shellout"
end
autoload :YAML, "yaml"

module ChefCLI
  module Command
    class Env < ChefCLI::Command::Base
      banner "Usage: #{ChefCLI::Dist::EXEC} env"

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new
      end

      def run(params)
        info = {}
        product_name = get_product_info
        info[product_name] = workstation_info
        info["Ruby"] = ruby_info
        info["Path"] = paths
        ui.msg YAML.dump(info)
      end

      def get_product_info
        if omnibus_install?
          ChefCLI::Dist::PRODUCT
        elsif habitat_chef_dke?
          ChefCLI::Dist::CHEF_DK_CLI_PACKAGE
        elsif habitat_standalone?
          ChefCLI::Dist::CHEF_CLI_PACKAGE
        else
          ChefCLI::Dist::PRODUCT
        end
      end

      def workstation_info
        info = { "Version" => ChefCLI::VERSION }
        if omnibus_install?
          info["Home"] = package_home
          info["Install Directory"] = omnibus_root
          info["Policyfile Config"] = policyfile_config
        elsif habitat_chef_dke? || habitat_standalone?
          info["Home"] = package_home
          info["Install Directory"] = get_chef_cli_path
          info["Policyfile Config"] = policyfile_config
        else
          info["Version"] = "Not running from within Workstation"
        end
        info
      end

      def ruby_info
        {}.tap do |ruby|
          ruby["Executable"] = Gem.ruby
          ruby["Version"] = RUBY_VERSION
          ruby["RubyGems"] = {}.tap do |rubygems|
            rubygems["RubyGems Version"] = Gem::VERSION
            rubygems["RubyGems Platforms"] = Gem.platforms.map(&:to_s)
            rubygems["Gem Environment"] = gem_environment
          end
        end
      end

      def gem_environment
        h = {}
        if habitat_install?
          # Habitat-specific environment variables
          h["GEM ROOT"] = habitat_env["GEM_ROOT"]
          h["GEM HOME"] = habitat_env["GEM_HOME"]
          h["GEM PATHS"] = habitat_env["GEM_PATH"].split(File::PATH_SEPARATOR)
        elsif omnibus_install?
          # Omnibus-specific environment variables
          h["GEM ROOT"] = omnibus_env["GEM_ROOT"]
          h["GEM HOME"] = omnibus_env["GEM_HOME"]
          h["GEM PATHS"] = omnibus_env["GEM_PATH"].split(File::PATH_SEPARATOR)
        else
          # Fallback to system environment variables if neither Omnibus nor Habitat
          h["GEM_ROOT"] = ENV["GEM_ROOT"] if ENV.key?("GEM_ROOT")
          h["GEM_HOME"] = ENV["GEM_HOME"] if ENV.key?("GEM_HOME")
          h["GEM PATHS"] = ENV["GEM_PATH"].split(File::PATH_SEPARATOR) if ENV.key?("GEM_PATH") && !ENV["GEM_PATH"].nil?
        end
        h
      end

      def paths
        env = habitat_install? ? habitat_env : omnibus_env
        env["PATH"].split(File::PATH_SEPARATOR)
      rescue OmnibusInstallNotFound
        ENV["PATH"].split(File::PATH_SEPARATOR)
      end

      def policyfile_config
        {}.tap do |h|
          h["Cache Path"] = CookbookOmnifetch.cache_path
          h["Storage Path"] = CookbookOmnifetch.storage_path.to_s
        end
      end

    end
  end
end
