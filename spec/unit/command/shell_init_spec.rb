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

require "spec_helper"
require "chef-cli/command/shell_init"

describe ChefCLI::Command::ShellInit do

  let(:expected_path) { [omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"], git_bin_dir].join(File::PATH_SEPARATOR) }
  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:command_instance) do
    ChefCLI::Command::ShellInit.new.tap do |c|
      allow(c).to receive(:stdout).and_return(stdout_io)
      allow(c).to receive(:stderr).and_return(stderr_io)
    end
  end

  shared_context "shell init script" do |shell|
    let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }
    let(:expected_gem_root) { Gem.default_dir.to_s }
    let(:expected_gem_home) { Gem.user_dir }
    let(:expected_gem_path) { Gem.path.join(File::PATH_SEPARATOR) }

    before do
      allow(::Dir).to receive(:exist?).and_call_original
      allow(command_instance).to receive(:habitat_install?).and_return(false)
    end

    context "with no explicit omnibus directory" do

      let(:omnibus_bin_dir) { "/foo/bin" }
      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }
      let(:git_bin_dir) { "/foo/gitbin" }
      let(:argv) { [shell] }

      before do
        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
        allow(command_instance).to receive(:git_bin_dir).and_return(git_bin_dir)
        allow(::Dir).to receive(:exist?).with(git_bin_dir).and_return(true)
      end

      it "emits a script to add ChefCLI's ruby to the shell environment" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_environment_commands)
      end

      it "does not emit any empty lines", if: %w{powershell posh}.include?(shell) do
        command_instance.run(argv)
        stdout_io.string.each_line do |s|
          expect(s.strip).not_to be_empty
        end
      end
    end

    context "with an explicit omnibus directory as an argument" do

      let(:omnibus_root) { File.join(fixtures_path, "eg_omnibus_dir/valid/") }
      let(:omnibus_bin_dir) { File.join(omnibus_root, "bin") }
      let(:omnibus_embedded_bin_dir) { File.join(omnibus_root, "embedded/bin") }
      let(:git_bin_dir) { File.join(omnibus_root, "gitbin") }

      let(:argv) { [shell, "--omnibus-dir", omnibus_root] }

      before do
        allow(::Dir).to receive(:exist?).with(git_bin_dir).and_return(true)
      end

      it "emits a script to add the package's ruby to the shell environment" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_environment_commands)
      end

      it "does not emit any empty lines", if: %w{powershell posh}.include?(shell) do
        command_instance.run(argv)
        stdout_io.string.each_line do |s|
          expect(s.strip).not_to be_empty
        end
      end
    end
  end

  shared_examples "a posix shell script" do |shell|
    before do
      stub_const("File::PATH_SEPARATOR", ":")
      allow(command_instance).to receive(:habitat_install?).and_return(false)
    end

    let(:expected_environment_commands) do
      <<~EOH
        export PATH="#{expected_path}"
        export GEM_ROOT="#{expected_gem_root}"
        export GEM_HOME="#{expected_gem_home}"
        export GEM_PATH="#{expected_gem_path}"
      EOH
    end
    include_context "shell init script", shell
  end

  shared_examples "a powershell script" do |shell|
    before do
      stub_const("File::PATH_SEPARATOR", ";")
      allow(command_instance).to receive(:habitat_install?).and_return(false)
    end

    let(:expected_environment_commands) do
      <<~EOH
        $env:PATH="#{expected_path}"
        $env:GEM_ROOT="#{expected_gem_root}"
        $env:GEM_HOME="#{expected_gem_home}"
        $env:GEM_PATH="#{expected_gem_path}"
      EOH
    end
    include_context "shell init script", shell
  end

  context "for sh" do
    it_behaves_like "a posix shell script", "sh"
  end

  context "for bash" do
    it_behaves_like "a posix shell script", "bash"

    describe "generating auto-complete" do

      let(:command_descriptions) do
        {
          "exec" => "Runs the command in context of the embedded ruby",
          "env" => "Prints environment variables used by #{ChefCLI::Dist::PRODUCT}",
          "gem" => "Runs the `gem` command in context of the embedded ruby",
          "generate" => "Generate a new app, cookbook, or component",
        }
      end

      let(:omnibus_bin_dir) { "/foo/bin" }
      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:argv) { [ "bash" ] }

      let(:expected_completion_function) do
        <<~END_COMPLETION
          _chef_comp() {
              local COMMANDS="exec env gem generate"
              COMPREPLY=($(compgen -W "$COMMANDS" -- ${COMP_WORDS[COMP_CWORD]} ))
          }
          complete -F _chef_comp chef
        END_COMPLETION
      end

      before do
        # Stub this or else we'd have to update the test every time a new command
        # is added.
        allow(command_instance).to receive(:habitat_install?).and_return(false)
        allow(command_instance.shell_completion_template_context).to receive(:commands)
          .and_return(command_descriptions)
        allow(command_instance.shell_completion_template_context).to receive(:habitat?).and_return(false)

        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "generates a completion function for the chef command" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_completion_function)
      end

    end
  end

  context "for zsh" do

    it_behaves_like "a posix shell script", "zsh"

    describe "generating auto-complete" do

      let(:command_descriptions) do
        {
          "exec" => "Runs the command in context of the embedded ruby",
          "env" => "Prints environment variables used by #{ChefCLI::Dist::PRODUCT}",
          "gem" => "Runs the `gem` command in context of the embedded ruby",
          "generate" => "Generate a new app, cookbook, or component",
        }
      end

      let(:omnibus_bin_dir) { "/foo/bin" }
      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:argv) { [ "zsh" ] }

      let(:expected_completion_function) do
        <<~END_COMPLETION
          function _chef() {

            local -a _1st_arguments
            _1st_arguments=(
                'exec:Runs the command in context of the embedded ruby'
                'env:Prints environment variables used by #{ChefCLI::Dist::PRODUCT}'
                'gem:Runs the `gem` command in context of the embedded ruby'
                'generate:Generate a new app, cookbook, or component'
              )

            _arguments \\
              '(-v --version)'{-v,--version}'[version information]' \\
              '*:: :->subcmds' && return 0

            if (( CURRENT == 1 )); then
              _describe -t commands "chef subcommand" _1st_arguments
              return
            fi
          }

          compdef _chef chef

        END_COMPLETION
      end

      before do
        # Stub this or else we'd have to update the test every time a new command
        # is added.
        allow(command_instance).to receive(:habitat_install?).and_return(false)
        allow(command_instance.shell_completion_template_context).to receive(:commands)
          .and_return(command_descriptions)

        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "generates a completion function for the chef command" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_completion_function)
      end
    end
  end

  context "for fish" do
    before do
      allow(command_instance).to receive(:habitat_install?).and_return(false)
      stub_const("File::PATH_SEPARATOR", ":")
    end

    let(:expected_path) { [omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"], git_bin_dir].join(":").split(":").join('" "') }
    let(:expected_environment_commands) do
      <<~EOH
        set -gx PATH "#{expected_path}" 2>/dev/null;
        set -gx GEM_ROOT "#{expected_gem_root}";
        set -gx GEM_HOME "#{expected_gem_home}";
        set -gx GEM_PATH "#{expected_gem_path}";
      EOH
    end

    include_context "shell init script", "fish"

    describe "generating auto-complete" do

      let(:command_descriptions) do
        {
          "exec" => "Runs the command in context of the embedded ruby",
          "env" => "Prints environment variables used by #{ChefCLI::Dist::PRODUCT}",
          "gem" => "Runs the `gem` command in context of the embedded Ruby",
          "generate" => "Generate a new repository, cookbook, or other component",
        }
      end

      let(:omnibus_bin_dir) { "/foo/bin" }
      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:argv) { [ "fish" ] }

      let(:expected_completion_function) do
        <<~END_COMPLETION

          # Fish Shell command-line completions for #{ChefCLI::Dist::PRODUCT}

          # set a list of all the chef commands in the Ruby chef-cli
          set -l chef_commands exec env gem generate;

          complete -c chef -f -n "not __fish_seen_subcommand_from $chef_commands" -a exec -d "Runs the command in context of the embedded ruby";
          complete -c chef -f -n "not __fish_seen_subcommand_from $chef_commands" -a env -d "Prints environment variables used by #{ChefCLI::Dist::PRODUCT}";
          complete -c chef -f -n "not __fish_seen_subcommand_from $chef_commands" -a gem -d "Runs the `gem` command in context of the embedded Ruby";
          complete -c chef -f -n "not __fish_seen_subcommand_from $chef_commands" -a generate -d "Generate a new repository, cookbook, or other component";

        END_COMPLETION
      end

      before do
        # Stub this or else we'd have to update the test every time a new command
        # is added.
        allow(command_instance.shell_completion_template_context).to receive(:commands)
          .and_return(command_descriptions)

        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "generates a completion function for the chef command" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_completion_function)
      end
    end
  end

  %w{powershell posh}.each do |shell|
    context "for #{shell}" do
      it_behaves_like "a powershell script", shell
    end
  end

  context "when no shell is specified" do

    let(:argv) { [] }

    it "exits with an error message" do
      expect(command_instance.run(argv)).to eq(1)
      expect(stderr_io.string).to include("Please specify what shell you are using")
    end

  end

  context "when an unsupported shell is specified" do

    let(:argv) { ["nosuchsh"] }

    it "exits with an error message" do
      expect(command_instance.run(argv)).to eq(1)
      expect(stderr_io.string).to include("Shell `nosuchsh' is not currently supported")
      expect(stderr_io.string).to include("Supported shells are: bash fish zsh sh powershell posh")
    end

  end

  context "habitat standalone shell-init on bash" do
    let(:cli_hab_path) { "/hab/pkgs/chef/chef-cli/1.0.0/123" }

    let(:argv) { ["bash"] }

    before do
      allow(command_instance).to receive(:habitat_chef_dke?).and_return(false)
      allow(command_instance).to receive(:habitat_standalone?).and_return(true)
    end

    it "should return the correct paths" do
      expect(command_instance).to receive(:get_pkg_prefix).with("chef/chef-cli").twice.and_return(cli_hab_path)

      command_instance.run(argv)
      expect(stdout_io.string).to include("export PATH=\"#{cli_hab_path}/bin")
      expect(stdout_io.string).to include("export GEM_HOME=\"#{cli_hab_path}/vendor")
      expect(stdout_io.string).to include("export GEM_PATH=\"#{cli_hab_path}/vendor")
    end
  end

  context "with chef-development-kit-enterprise habitat pkg shell-init on bash" do

    let(:chef_dke_path) { "/hab/pkgs/chef/chef-development-kit-enterprise/1.0.0/123" }
    let(:cli_hab_path) { "/hab/pkgs/chef/chef-cli/1.0.0/123" }

    let(:argv) { ["bash"] }

    before do
      allow(command_instance).to receive(:habitat_chef_dke?).and_return(true)
      allow(command_instance).to receive(:habitat_standalone?).and_return(false)
    end

    it "should return the correct paths" do
      expect(command_instance).to receive(:get_pkg_prefix).with("chef/chef-development-kit-enterprise").and_return(chef_dke_path)
      expect(command_instance).to receive(:get_pkg_prefix).with("chef/chef-cli").and_return(cli_hab_path)

      command_instance.run(argv)
      expect(stdout_io.string).to include("export PATH=\"#{chef_dke_path}/bin")
      expect(stdout_io.string).to include("export GEM_HOME=\"#{cli_hab_path}/vendor")
      expect(stdout_io.string).to include("export GEM_PATH=\"#{cli_hab_path}/vendor")
    end

    describe "autocompletion" do
      let(:command_descriptions) do
        {
          "exec" => "Runs the command in context of the embedded ruby",
          "env" => "Prints environment variables used by #{ChefCLI::Dist::PRODUCT}",
          "gem" => "Runs the `gem` command in context of the embedded ruby",
          "generate" => "Generate a new app, cookbook, or component",
        }
      end

      let(:omnibus_bin_dir) { "/foo/bin" }
      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:argv) { [ "bash" ] }

      let(:expected_completion_function) do
        <<~END_COMPLETION
          _chef_comp() {
              local COMMANDS="exec env gem generate"
              COMPREPLY=($(compgen -W "$COMMANDS" -- ${COMP_WORDS[COMP_CWORD]} ))
          }
          complete -F _chef_comp chef-cli
        END_COMPLETION
      end

      before do
        # Stub this or else we'd have to update the test every time a new command
        # is added.
        allow(command_instance).to receive(:get_pkg_prefix).with("chef/chef-development-kit-enterprise").and_return(chef_dke_path)
        allow(command_instance).to receive(:get_pkg_prefix).with("chef/chef-cli").and_return(cli_hab_path)
        allow(command_instance.shell_completion_template_context).to receive(:commands)
          .and_return(command_descriptions)
        allow(command_instance.shell_completion_template_context).to receive(:habitat?).and_return(true)

        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "generates a completion function for the chef command" do
        command_instance.run(argv)
        expect(stdout_io.string).to include(expected_completion_function)
      end

      it "should generate the autocompletion" do

      end
    end
  end
end
