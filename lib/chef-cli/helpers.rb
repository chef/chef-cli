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

module Mixlib
  autoload :ShellOut, "mixlib/shellout"
end

require_relative "exceptions"

module ChefCLI
  module Helpers
    extend self

    #
    # Runs given commands using mixlib-shellout
    #
    def system_command(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      cmd
    end

    def err(message)
      stderr.print("#{message}\n")
    end

    def msg(message)
      stdout.print("#{message}\n")
    end

    def stdout
      $stdout
    end

    def stderr
      $stderr
    end

    #
    # Locates the omnibus directories
    #
    def omnibus_install?
      # We also check if the location we're running from (omnibus_root is relative to currently-running ruby)
      # includes the version manifest that omnibus packages ship with. If it doesn't, then we're running locally
      # or out of a gem - so not as an 'omnibus install'
      File.exist?(expected_omnibus_root) && File.exist?(File.join(expected_omnibus_root, "version-manifest.json"))
    end

    # The habitat version of the chef-cli can be installed with standalone or chef-development-kit-enterprise
    # This method checks if the habitat version of chef-cli is installed as standalone
    def habitat_standalone?
      @hab_standalone ||= (hab_pkg_installed?(ChefCLI::Dist::HAB_PKG_NAME) && !habitat_chef_dke?)
    end

    # This method checks if the habitat version of chef-cli is installed with chef-development-kit-enterprise
    def habitat_chef_dke?
      @hab_dke ||= hab_pkg_installed?(ChefCLI::Dist::CHEF_DKE_PKG_NAME)
    end

    def habitat_install?
      habitat_chef_dke? || habitat_standalone?
    end

    def omnibus_root
      @omnibus_root ||= omnibus_expand_path(expected_omnibus_root)
    end

    def omnibus_bin_dir
      @omnibus_bin_dir ||= omnibus_expand_path(omnibus_root, "bin")
    end

    def omnibus_embedded_bin_dir
      @omnibus_embedded_bin_dir ||= omnibus_expand_path(omnibus_root, "embedded", "bin")
    end

    def package_home
      @package_home ||= begin
                         package_home_set = !([nil, ""].include? ENV["CHEF_WORKSTATION_HOME"])
                         if package_home_set
                           ENV["CHEF_WORKSTATION_HOME"]
                         else
                           default_package_home
                         end
                       end
    end

    # Function to return the Chef CLI path based on standalone or Chef-DK-enabled package
    def get_chef_cli_path
      # Check Chef-DK package path
      chef_dk_path = get_hab_package_path(ChefCLI::Dist::CHEF_DKE_PKG_NAME)
      return chef_dk_path if chef_dk_path && File.exist?(chef_dk_path)

      # Check Standalone Chef-CLI package path
      chef_cli_path = get_hab_package_path(ChefCLI::Dist::HAB_PKG_NAME)
      return chef_cli_path if chef_cli_path && File.exist?(chef_cli_path)
    rescue
      nil
    end

    # Returns the directory that contains our main symlinks.
    # On Mac we place all of our symlinks under /usr/local/bin on other
    # platforms they are under /usr/bin
    def usr_bin_prefix
      @usr_bin_prefix ||= macos? ? "/usr/local/bin" : "/usr/bin"
    end

    # Returns the full path to the given command under usr_bin_prefix
    def usr_bin_path(command)
      File.join(usr_bin_prefix, command)
    end

    # Unix users do not want git on their path if they already have it installed.
    # Because we put `embedded/bin` on the path we must move the git binaries
    # somewhere else that we can append to the end of the path.
    # This is only a temporary solution - see https://github.com/chef/chef-cli/issues/854
    # for a better proposed solution.
    def git_bin_dir
      @git_bin_dir ||= File.expand_path(File.join(omnibus_root, "gitbin"))
    end

    # In our Windows ChefCLI omnibus package we include Git For Windows, which
    # has a bunch of helpful unix utilties (like ssh, scp, etc.) bundled with it
    def git_windows_bin_dir
      @git_windows_bin_dir ||= File.expand_path(File.join(omnibus_root, "embedded", "git", "usr", "bin"))
    end

    #
    # environment vars for habitat
    #
    def habitat_env
      @habitat_env ||=
      begin
        # Define the necessary paths for the Habitat environment
        # If it is a chef-dke installation, we will use the chef-dke bin path.
        # Otherwise, we will use the chef-cli bin path.
        bin_pkg_prefix = get_pkg_prefix(habitat_chef_dke? ? ChefCLI::Dist::CHEF_DKE_PKG_NAME : ChefCLI::Dist::HAB_PKG_NAME)
        vendor_dir = File.join(get_pkg_prefix(ChefCLI::Dist::HAB_PKG_NAME), "vendor")
        path = [
          File.join(bin_pkg_prefix, "bin"),
          ENV["PATH"].split(File::PATH_SEPARATOR), # Preserve existing PATH
        ].flatten.uniq

        {
        "PATH" => path.join(File::PATH_SEPARATOR),
        "GEM_ROOT" => Gem.default_dir, # Default directory for gems
        "GEM_HOME" => vendor_dir,  # GEM_HOME pointing to the vendor directory
        "GEM_PATH" => vendor_dir,  # GEM_PATH also pointing to the vendor directory
        }
      end
    end

    #
    # environment vars for omnibus
    #
    def omnibus_env
      @omnibus_env ||=
        begin
          user_bin_dir = File.expand_path(File.join(Gem.user_dir, "bin"))
          path = [ omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"].split(File::PATH_SEPARATOR) ]
          path << git_bin_dir if Dir.exist?(git_bin_dir)
          path << git_windows_bin_dir if Dir.exist?(git_windows_bin_dir)
          {
            "PATH" => path.flatten.uniq.join(File::PATH_SEPARATOR),
            "GEM_ROOT" => Gem.default_dir,
            "GEM_HOME" => Gem.user_dir,
            "GEM_PATH" => Gem.path.join(File::PATH_SEPARATOR),
          }
        end
    end

    def get_pkg_prefix(pkg_name)
      path = `hab pkg path #{pkg_name}`.strip

      if $?.success? && !path.empty?
        path
      else
        raise "Failed to get pkg_prefix for #{pkg_name}: #{path}"
      end
    end

    def omnibus_expand_path(*paths)
      dir = File.expand_path(File.join(paths))
      raise OmnibusInstallNotFound.new unless dir && File.directory?(dir)

      dir
    end

    private

    def expected_omnibus_root
      File.expand_path(File.join(Gem.ruby, "..", "..", ".."))
    end

    def default_package_home
      if Chef::Platform.windows?
        File.join(ENV["LOCALAPPDATA"], ChefCLI::Dist::PRODUCT_PKG_HOME).gsub("\\", "/")
      else
        File.expand_path("~/.#{ChefCLI::Dist::PRODUCT_PKG_HOME}")
      end
    end

    # Open a file. By default, the mode is for read+write,
    # and binary so that windows writes out what we tell it,
    # as this is the most common case we have.
    def with_file(path, mode = "wb+", &block)
      File.open(path, mode, &block)
    end

    # @api private
    # This method resets all the instance variables used. It
    # should only be used for testing
    def reset!
      instance_variables.each do |ivar|
        instance_variable_set(ivar, nil)
      end
    end

    # @return [Boolean] Returns true if we are on macOS. Otherwise false
    #
    # @api private
    #
    def macos?
      !!(RUBY_PLATFORM =~ /darwin/)
    end

    # @return [Boolean] Checks if a habitat package is installed.
    # If habitat itself is not installed, this method will return false.
    #
    # @api private
    #
    def hab_pkg_installed?(pkg_name)
      `hab pkg list #{pkg_name} 2>/dev/null`.include?(pkg_name) rescue false
    end

    # Helper function to get the path of the given hab package
    def get_hab_package_path(pkg_name)
      path = `hab pkg path #{pkg_name} 2>/dev/null`.strip
      $?.success? && !path.empty? ? path : nil
    rescue
      nil
    end

  end
end
