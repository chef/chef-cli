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
require_relative "../ui"
require_relative "../policyfile_services/install"
require_relative "../configurable"
require_relative "../dist"

module ChefCLI
  module Command

    class Install < Base

      include Configurable

      banner(<<~E)
        Usage: #{ChefCLI::Dist::EXEC} install [ POLICY_FILE ] [options]

        `#{ChefCLI::Dist::EXEC} install` evaluates a `Policyfile.rb` to find a compatible set of
        cookbooks for the policy's run_list and caches them locally. It emits a
        Policyfile.lock.json describing the locked cookbook set. You can use the
        lockfile to install the locked cookbooks on another machine. You can also push
        the lockfile to a "policy group" on a #{ChefCLI::Dist::SERVER_PRODUCT} and apply that exact set of
        cookbooks to nodes in your infrastructure.

        See our detailed README for more information:

        https://docs.chef.io/policyfile/

        Options:

      E

      attr_reader :policyfile_relative_path

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new

        @policyfile_relative_path = nil
        @installer = nil
      end

      def run(params = [])
        return 1 unless apply_params!(params)

        # Force config file to be loaded. We don't use the configuration
        # directly, but the user may have SSL configuration options that they
        # need to talk to a private supermarket (e.g., trusted_certs or
        # ssl_verify_mode)
        chef_config
        installer.run
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def installer
        @installer ||= PolicyfileServices::Install.new(policyfile: policyfile_relative_path, ui:, root_dir: Dir.pwd, config: chef_config)
      end

      def debug?
        !!config[:debug]
      end

      def config_path
        config[:config_file]
      end

      def handle_error(error)
        ui.err("Error: #{error.message}")
        if error.respond_to?(:reason)
          ui.err("Reason: #{error.reason}")
          ui.err("")
          ui.err(error.extended_error_info) if debug?
          ui.err(error.cause.backtrace.join("\n")) if debug?
        end
      end

      def apply_params!(params)
        remaining_args = parse_options(params)
        if remaining_args.size > 1
          ui.err(opt_parser)
          false
        else
          @policyfile_relative_path = remaining_args.first
          true
        end
      end

    end
  end
end
