#
# Copyright:: Copyright (c) 2014-2019 Chef Software Inc.
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
require_relative "../test_config"
require_relative "../dist"

module ChefCLI
  module Command

    class Test < Base

      banner(<<~E)
        Usage: #{ChefCLI::Dist::EXEC} test [PHASE] [options]

        `#{ChefCLI::Dist::EXEC} test` tests your cookbook code using existing Delivery Local-Mode configuration files at .delivery/project.toml

        Options:

      E

      option :config_file,
        short:       "-c CONFIG_FILE",
        long:        "--config CONFIG_FILE",
        description: "Path to configuration file",
        default:     File.expand_path(".delivery/project.toml")

      option :debug,
        short:       "-D",
        long:        "--debug",
        description: "Enable stacktraces and other debug output",
        default:     false

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new
        @test_config = TestConfig.new(config_path)
      end

      def run(params)
        @test_config.validate!

        # start by building out a hash of what phases to run so we can fail
        # if any of the phases were invalid before we start
        commands_to_run(params).each do |phase, command|
          puts "Running phase #{phase} command #{command}"
        end
      end

      def debug?
        !!config[:debug]
      end

      def config_path
        config[:config_file]
      end

      private

      def commands_to_run(phases)
        # if no phase or all specified then return all phases
        return @test_config.config_hash["local_phases"] if phases.empty? || phases.include?("all")

        to_run = {}

        phases.each do |phase|
          to_run[phase] = lookup_phase_cmd(phase)
        end

        to_run
      end

      def lookup_phase_cmd(phase)
        raise "Phase #{phase} not found in #{config_path}!" unless @test_config.config_hash["local_phases"].key?(phase)

        @test_config.config_hash["local_phases"][phase]
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
    end
  end
end
