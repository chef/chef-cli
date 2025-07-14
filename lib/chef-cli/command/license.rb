# frozen_string_literal: true

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
require "chef-cli/licensing/base"
require_relative "../configurable"

module ChefCLI
  module Command

    # This class will manage the license command in the chef-cli
    class License < Base

      include Configurable

      MAIN_COMMAND_HELP = <<~HELP.freeze
        Usage: #{ChefCLI::Dist::EXEC} license [SUBCOMMAND]

        `#{ChefCLI::Dist::EXEC} license` command will validate the existing license
        or will help you interactively generate new free/trial license and activate the
        commercial license the chef team has sent you through email.
      HELP

      SUB_COMMANDS = [
        { name: "list", description: "List details of the license(s) installed on the system." },
        { name: "add", description: "Create & install a Free/ Trial license or install a Commercial license on the system." },
      ].freeze

      option :chef_license_key,
        long: "--chef-license-key LICENSE",
        description: "New license key to accept and store in the system"

      attr_accessor :ui

      def self.banner
        <<~BANNER
          #{MAIN_COMMAND_HELP}
          Subcommands:
          #{SUB_COMMANDS.map do |c|
            "  #{c[:name].ljust(7)}#{c[:description]}"
          end.join("\n") }

          Options:
        BANNER
      end

      def initialize
        super

        @ui = UI.new
      end

      def run(params)
        config_license_debug if debug?
        remaining_args = parse_options(params)
        return 1 unless validate_params!(remaining_args)

        if remaining_args.empty?
          ChefCLI::Licensing::Base.validate
        else
          ChefCLI::Licensing::Base.send(remaining_args[0])
        end
      rescue ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError
        ui.msg("License key not fetched. Please try again.")
      end

      def debug?
        !!config[:debug]
      end

      def validate_params!(args)
        if args.length > 1
          ui.err("Too many arguments")
          return false
        end

        valid_subcommands = SUB_COMMANDS.collect { |c| c[:name] }
        args.each do |arg|
          next if valid_subcommands.include?(arg)

          ui.err("Invalid option: #{arg}")
          return false
        end

        true
      end

      private

      def config_license_debug
        ChefLicensing.output = ui
      end
    end
  end
end
