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
require_relative "../../dist"

module ChefCLI
  module Command
    module GeneratorCommands

      # ## CookbookFile
      # chef generate cookbook path/to/basename --generator-cookbook=path/to/generator
      #
      # Generates a basic cookbook directory structure. Most file types are
      # omitted, the user is expected to add additional files as needed using
      # the relevant generators.
      class Cookbook < Base

        banner "Usage: #{ChefCLI::Dist::EXEC} generate cookbook NAME [options]"

        attr_reader :errors

        attr_reader :cookbook_name_or_path

        option :berks,
          short:       "-b",
          long:        "--berks",
          description: "Generate cookbooks using Berkshelf dependency resolution.",
          boolean:     true,
          default:     nil

        option :kitchen,
          long:        "--kitchen CONFIGURATION",
          description: "Generate cookbooks with a specific Test Kitchen configuration (dokken|vagrant) - defaults to vagrant",
          default:     "vagrant"

        option :policy,
          short:        "-P",
          long:         "--policy",
          description:  "Generate a cookbook using Policyfile dependency resolution (default).",
          boolean:      true,
          default:      nil

        option :specs,
          short:        "-s",
          long:         "--specs",
          description:  "Generate a cookbook with sample ChefSpec specs",
          boolean:      true,
          default:      nil

        option :workflow,
          short:        "-w",
          long:         "--workflow",
          description:  "REMOVED: #{ChefCLI::Dist::WORKFLOW} is EOL. This option has been removed.",
          boolean:      true,
          default:      false

        option :verbose,
          short:        "-V",
          long:         "--verbose",
          description:  "Show detailed output from the generator",
          boolean:      true,
          default:      false

        option :yaml,
          short:        "-y",
          long:         "--yaml",
          description:  "Generate a cookbook with YAML Recipe configuration file as the default.",
          boolean:      true,
          default:      nil

        option :pipeline,
          long:         "--pipeline PIPELINE",
          description:  "REMOVED: #{ChefCLI::Dist::WORKFLOW} is EOL. This option has been removed.",
          default:      nil

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @cookbook_name = nil
          @policy_mode = true
          @verbose = false
          @specs = false
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            msg("Generating cookbook #{cookbook_name}")
            chef_runner.converge
            msg("")
            emit_post_create_message
            0
          else
            err(opt_parser)
            1
          end
        rescue ChefCLI::ChefRunnerError => e
          err("ERROR: #{e}")
          1
        end

        def emit_post_create_message
          default_recipe_file = yaml ? "default.yml" : "default.rb"
          msg("Your cookbook is ready. Type `cd #{cookbook_name_or_path}` to enter it.")
          msg("\nThere are several commands you can run to get started locally developing and testing your cookbook.")
          msg("\nWhy not start by writing an InSpec test? Tests for the default recipe are stored at:\n")
          msg("test/integration/default/default_test.rb")
          msg("\nIf you'd prefer to dive right in, the default recipe can be found at:")
          msg("\nrecipes/#{default_recipe_file}\n")
        end

        def setup_context
          super
          Generator.add_attr_to_context(:skip_git_init, cookbook_path_in_git_repo?)
          Generator.add_attr_to_context(:cookbook_root, cookbook_root)
          Generator.add_attr_to_context(:cookbook_name, cookbook_name)
          Generator.add_attr_to_context(:recipe_name, recipe_name)
          Generator.add_attr_to_context(:include_chef_repo_source, false)
          Generator.add_attr_to_context(:policy_name, policy_name)
          Generator.add_attr_to_context(:policy_run_list, policy_run_list)
          Generator.add_attr_to_context(:policy_local_cookbook, ".")

          Generator.add_attr_to_context(:verbose, verbose?)
          Generator.add_attr_to_context(:specs, specs?)

          Generator.add_attr_to_context(:use_policyfile, policy_mode?)
          Generator.add_attr_to_context(:kitchen, kitchen)
          Generator.add_attr_to_context(:vscode_dir, create_vscode_dir?)
          Generator.add_attr_to_context(:yaml, yaml)
        end

        def kitchen
          config[:kitchen]
        end

        def yaml
          config[:yaml]
        end

        def policy_name
          cookbook_name
        end

        def policy_run_list
          "#{cookbook_name}::#{recipe_name}"
        end

        def recipe
          "cookbook"
        end

        def recipe_name
          "default"
        end

        def cookbook_name
          File.basename(cookbook_full_path)
        end

        def cookbook_root
          File.dirname(cookbook_full_path)
        end

        def cookbook_full_path
          if !cookbook_name_or_path.nil? && !cookbook_name_or_path.empty?
            File.expand_path(cookbook_name_or_path, Dir.pwd)
          else
            ""
          end
        end

        def policy_mode?
          @policy_mode
        end

        def verbose?
          @verbose
        end

        def specs?
          @specs
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @cookbook_name_or_path = arguments[0]

          if !@cookbook_name_or_path
            @params_valid = false
          elsif File.basename(@cookbook_name_or_path).include?("-")
            msg("Hyphens are discouraged in cookbook names as they may cause problems with custom resources. See https://docs.chef.io/workstation/ctl_chef/#chef-generate-cookbook for more information.")
          end

          if !generator_cookbook_path.empty? &&
              !cookbook_full_path.empty? &&
              File.identical?(Pathname.new(cookbook_full_path).parent, generator_cookbook_path)
            err("The generator and the cookbook cannot be in the same directory. Please specify a cookbook directory that is different from the generator's parent.")
            @params_valid = false
          end

          if config[:berks] && config[:policy]
            err("Berkshelf and Policyfiles are mutually exclusive. Please specify only one.")
            @params_valid = false
          end

          if config[:workflow] || config[:pipeline]
            err("[DEPRECATION] Chef Workflow (Delivery) is end of life (EOL) as of December 31, 2020 and the --workflow and --pipeline flags have been removed")
            @params_valid = false
          end

          if config[:berks]
            @policy_mode = false
          end

          if config[:verbose]
            @verbose = true
          end

          if config[:specs]
            @specs = true
          end

          true
        end

        def params_valid?
          @params_valid
        end

        def cookbook_path_in_git_repo?
          Pathname.new(cookbook_full_path).ascend do |dir|
            return true if File.directory?(File.join(dir.to_s, ".git"))
          end
          false
        end

        def create_vscode_dir?
          ::File.exist?("/Applications/Visual Studio Code.app") || ::File.exist?("#{ENV["APPDATA"]}\\Code")
        end
      end
    end
  end
end
