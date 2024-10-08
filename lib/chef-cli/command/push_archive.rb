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
require_relative "../policyfile_services/push_archive"
require_relative "../configurable"
require_relative "../dist"

module ChefCLI
  module Command

    class PushArchive < Base

      include Configurable

      banner(<<~E)
        Usage: #{ChefCLI::Dist::EXEC} push-archive POLICY_GROUP ARCHIVE_FILE [options]

        `#{ChefCLI::Dist::EXEC} push-archive` publishes a policy archive to a #{ChefCLI::Dist::SERVER_PRODUCT}. Policy
        archives can be created with `chef export -a`. The policy will be applied to
        the given POLICY_GROUP, which is a set of nodes that share the same
        run_list and cookbooks.

        For more information about Policyfiles, see our detailed README:

        https://docs.chef.io/policyfile/

        Options:
      E

      attr_accessor :ui

      attr_reader :policy_group

      attr_reader :archive_path

      def initialize(*args)
        super
        @policy_group = nil
        @archive_path = nil
        @chef_config = nil
        @ui = UI.new
      end

      def run(params)
        return 1 unless apply_params!(params)

        push_archive_service.run

        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      # @api private
      def handle_error(error)
        ui.err("Error: #{error.message}")
        if error.respond_to?(:reason)
          ui.err("Reason: #{error.reason}")
          ui.err("")
          ui.err(error.extended_error_info) if debug?
          ui.err(error.cause.backtrace.join("\n")) if debug?
        end
      end

      # @api private
      def push_archive_service
        @push_archive_service ||=
          ChefCLI::PolicyfileServices::PushArchive.new(
            archive_file:,
            policy_group:,
            ui:,
            config: chef_config
          )
      end

      def archive_file
        File.expand_path(archive_path)
      end

      # @api private
      def debug?
        !!config[:debug]
      end

      # @api private
      def apply_params!(params)
        remaining_args = parse_options(params)
        if remaining_args.size != 2
          ui.err(opt_parser)
          return false
        end

        @policy_group, @archive_path = remaining_args
      end

    end
  end
end
