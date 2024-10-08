#
# Copyright:: Copyright (c) Chef Software Inc.
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
require_relative "../policyfile_services/export_repo"
require_relative "../configurable"
require_relative "../dist"

module ChefCLI
  module Command

    class Export < Base

      include Configurable

      banner(<<~E)
        Usage: #{ChefCLI::Dist::EXEC} export [ POLICY_FILE ] DESTINATION_DIRECTORY [options]

        `#{ChefCLI::Dist::EXEC} export` creates a #{ChefCLI::Dist::ZERO_PRODUCT} compatible #{ChefCLI::Dist::INFRA_PRODUCT} repository containing the
        cookbooks described in a Policyfile.lock.json. The exported repository also contains
        a .chef/config.rb which configures #{ChefCLI::Dist::INFRA_CLIENT_PRODUCT} to apply your policy. Once the
        exported repo is copied to the target machine, you can apply the policy to the
        machine with:

        `#{ChefCLI::Dist::INFRA_CLIENT_CLI} -z`.

        See our detailed README for more information:

        https://docs.chef.io/policyfile/

        Options:

      E

      option :archive,
        short:       "-a",
        long:        "--archive",
        description: "Export as a tarball archive rather than a directory",
        default:     false,
        boolean:     true

      option :force,
        short:       "-f",
        long:        "--force",
        description: "If the DESTINATION_DIRECTORY is not empty, remove its content.",
        default:     false,
        boolean:     true

      option :debug,
        short:       "-D",
        long:        "--debug",
        description: "Enable stacktraces and other debug output",
        default:     false

      option :policy_group,
        long:        "--policy-group POLICY_GROUP",
        description: "The policy_group to include in the export (default: 'local')",
        default:     nil

      attr_reader :policyfile_relative_path
      attr_reader :export_dir

      attr_accessor :ui

      def initialize(*args)
        super
        @push = nil
        @ui = nil
        @policyfile_relative_path = nil
        @export_dir = nil
        @chef_config = nil
        @ui = UI.new
      end

      def run(params = [])
        return 1 unless apply_params!(params)

        export_service.run
        ui.msg("Exported policy '#{export_service.policyfile_lock.name}' to #{export_target}")
        unless archive?
          ui.msg("")
          ui.msg("To converge this system with the exported policy, run:")
          ui.msg("  cd #{export_dir}")
          ui.msg("  #{ChefCLI::Dist::INFRA_CLIENT_CLI} -z")
        end
        0
      rescue ExportDirNotEmpty => e
        ui.err("ERROR: " + e.message)
        ui.err("Use --force to force export")
        1
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def export_target
        if archive?
          export_service.archive_file_location
        else
          export_dir
        end
      end

      def debug?
        !!config[:debug]
      end

      def archive?
        !!config[:archive]
      end

      def export_service
        @export_service ||= PolicyfileServices::ExportRepo.new(
          policyfile: policyfile_relative_path,
          export_dir:,
          root_dir: Dir.pwd,
          archive: archive?,
          force: config[:force],
          policy_group: config[:policy_group]
        )
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
        case remaining_args.size
        when 1
          @export_dir = remaining_args[0]
        when 2
          @policyfile_relative_path, @export_dir = remaining_args
        else
          ui.err(opt_parser)
          ui.err("\n")
          return false
        end
        true
      end

    end
  end
end
