#
# Copyright:: Copyright (c) 2014-2020 Chef Software Inc.
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
require "shared/custom_generator_cookbook"
require "shared/setup_git_committer_config"
require "chef-cli/command/generator_commands/cookbook"

describe ChefCLI::Command::GeneratorCommands::Cookbook do

  include_context("setup_git_committer_config")

  let(:argv) { %w{new_cookbook} }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w{
      .gitignore
      kitchen.yml
      test
      test/integration
      test/integration/default/default_test.rb
      Policyfile.rb
      chefignore
      LICENSE
      metadata.rb
      README.md
      CHANGELOG.md
      recipes
      recipes/default.rb
      compliance/README.md
    }
  end

  let(:expected_cookbook_file_relpaths_specs) do
    %w{
      .gitignore
      kitchen.yml
      test
      test/integration
      test/integration/default/default_test.rb
      Policyfile.rb
      chefignore
      LICENSE
      metadata.rb
      README.md
      CHANGELOG.md
      recipes
      recipes/default.rb
      spec
      spec/spec_helper.rb
      spec/unit
      spec/unit/recipes
      spec/unit/recipes/default_spec.rb
      compliance/README.md
    }
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_cookbook", relpath)
    end
  end

  let(:expected_cookbook_files_specs) do
    expected_cookbook_file_relpaths_specs.map do |relpath|
      File.join(tempdir, "new_cookbook", relpath)
    end
  end

  let(:non_delivery_breadcrumb) do
    <<~EOF
      Your cookbook is ready. Type `cd new_cookbook` to enter it.

      There are several commands you can run to get started locally developing and testing your cookbook.

      Why not start by writing an InSpec test? Tests for the default recipe are stored at:

      test/integration/default/default_test.rb

      If you'd prefer to dive right in, the default recipe can be found at:

      recipes/default.rb
    EOF
  end

  subject(:cookbook_generator) do
    g = described_class.new(argv)
    allow(g).to receive(:cookbook_path_in_git_repo?).and_return(false)
    allow(g).to receive(:stdout).and_return(stdout_io)
    g
  end

  def generator_context
    ChefCLI::Generator.context
  end

  before do
    ChefCLI::Generator.reset
  end

  include_examples "custom generator cookbook" do

    let(:generator_arg) { "new_cookbook" }

    let(:generator_name) { "cookbook" }

  end

  it "configures the chef runner" do
    expect(cookbook_generator.chef_runner).to be_a(ChefCLI::ChefRunner)
    expect(cookbook_generator.chef_runner.cookbook_path).to eq(File.expand_path("lib/chef-cli/skeletons", project_root))
  end

  context "when given invalid/incomplete arguments" do

    let(:expected_help_message) do
      "Usage: chef generate cookbook NAME [options]\n"
    end

    def with_argv(argv)
      generator = described_class.new(argv)
      allow(generator).to receive(:stdout).and_return(stdout_io)
      allow(generator).to receive(:stderr).and_return(stderr_io)
      generator
    end

    it "prints usage when args are empty" do
      with_argv([]).run
      expect(stderr_io.string).to include(expected_help_message)
    end

    it "errors if both berks and policyfiles are requested" do
      expect(with_argv(%w{my_cookbook --berks --policy}).run).to eq(1)
      message = "Berkshelf and Policyfiles are mutually exclusive. Please specify only one."
      expect(stderr_io.string).to include(message)
    end

    it "errors if cookbook parent folder is same as generator parent folder" do
      expect(with_argv(%w{ my_cookbook -g my_generator }).run).to eq(1)
      message = "The generator and the cookbook cannot be in the same directory. Please specify a cookbook directory that is different from the generator's parent."
      expect(stderr_io.string).to include(message)
    end

    it "warns if a hyphenated cookbook name is passed" do
      expect(with_argv(%w{my-cookbook}).run).to eq(0)
      message = "Hyphens are discouraged in cookbook names as they may cause problems with custom resources. See https://docs.chef.io/workstation/ctl_chef/#chef-generate-cookbook for more information."
      expect(stdout_io.string).to include(message)
    end

  end

  context "when given the name of the cookbook to generate" do

    let(:argv) { %w{new_cookbook} }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
      expect(generator_context.recipe_name).to eq("default")
      expect(generator_context.verbose).to be(false)
      expect(generator_context.specs).to be(false)
    end

    it "creates a new cookbook" do

      Dir.chdir(tempdir) do
        allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        expect(cookbook_generator.run).to eq(0)
      end
      generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
      end
    end

    context "when given the specs flag" do

      let(:argv) { %w{ new_cookbook --specs } }

      it "configures the generator context with specs mode enabled" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.specs).to be(true)
      end

      it "creates a new cookbook" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
        generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
        expected_cookbook_files_specs.each do |expected_file|
          expect(generated_files).to include(expected_file)
        end
      end
    end

    context "when given the verbose flag" do

      let(:argv) { %w{ new_cookbook --verbose } }

      it "configures the generator context with verbose mode enabled" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.verbose).to be(true)
      end

      it "emits verbose output" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end

        # The normal chef formatter puts a heading for each recipe like this.
        # Full output is large and subject to change with minor changes in the
        # generator cookbook, so we just look for this line
        expected_line = "Recipe: code_generator::cookbook"

        actual = stdout_io.string

        expect(actual).to include(expected_line)
      end
    end

    shared_examples_for "a generated file" do |context_var|
      before do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end

      it "should contain #{context_var} from the generator context" do
        expect(File.read(file)).to match line
      end
    end

    describe "README.md" do
      let(:file) { File.join(tempdir, "new_cookbook", "README.md") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# new_cookbook" }
      end
    end

    describe "CHANGELOG.md" do
      let(:file) { File.join(tempdir, "new_cookbook", "CHANGELOG.md") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# new_cookbook" }
      end
    end

    # This shared example group requires a let binding for
    # `expected_kitchen_yml_content`
    shared_examples_for "kitchen_yml_and_integration_tests" do

      describe "Generating Test Kitchen and integration testing files" do

        describe "generating kitchen config" do

          before do
            Dir.chdir(tempdir) do
              allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
              expect(cookbook_generator.run).to eq(0)
            end
          end

          let(:file) { File.join(tempdir, "new_cookbook", "kitchen.yml") }

          it "creates a kitchen.yml with the expected content" do
            expect(IO.read(file)).to eq(expected_kitchen_yml_content)
          end

        end

        describe "test/integration/default/default_test.rb" do
          let(:file) { File.join(tempdir, "new_cookbook", "test", "integration", "default", "default_test.rb") }

          include_examples "a generated file", :cookbook_name do
            let(:line) { "describe port" }
          end
        end
      end
    end

    # This shared example group requires you to define a let binding for
    # `expected_chefspec_spec_helper_content`
    shared_examples_for "chefspec_spec_helper_file" do

      describe "Generating ChefSpec files" do

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        let(:file) { File.join(tempdir, "new_cookbook", "spec", "spec_helper.rb") }

        it "creates a spec/spec_helper.rb for ChefSpec with the expected content" do
          expect(IO.read(file)).to eq(expected_chefspec_spec_helper_content)
        end

      end

    end

    context "when configured for Policyfiles" do

      let(:argv) { %w{new_cookbook --policy} }

      describe "Policyfile.rb" do

        let(:file) { File.join(tempdir, "new_cookbook", "Policyfile.rb") }

        let(:expected_content) do
          <<~POLICYFILE_RB
            # Policyfile.rb - Describe how you want Chef Infra Client to build your system.
            #
            # For more information on the Policyfile feature, visit
            # https://docs.chef.io/policyfile/

            # A name that describes what the system you're building with Chef does.
            name 'new_cookbook'

            # Where to find external cookbooks:
            default_source :supermarket

            # run_list: chef-client will run these recipes in the order specified.
            run_list 'new_cookbook::default'

            # Specify a custom source for a single cookbook:
            cookbook 'new_cookbook', path: '.'
          POLICYFILE_RB
        end

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "has a run_list and cookbook path that will work out of the box" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      include_examples "kitchen_yml_and_integration_tests" do

        let(:expected_kitchen_yml_content) do
          <<~KITCHEN_YML
            ---
            driver:
              name: vagrant

            ## The forwarded_port port feature lets you connect to ports on the VM guest
            ## via localhost on the host.
            ## see also: https://www.vagrantup.com/docs/networking/forwarded_ports

            #  network:
            #    - ["forwarded_port", {guest: 80, host: 8080}]

            provisioner:
              name: chef_zero

              ## product_name and product_version specifies a specific Chef product and version to install.
              ## see the Chef documentation for more details: https://docs.chef.io/workstation/config_yml_kitchen/
              #  product_name: chef
              #  product_version: 17

            verifier:
              name: inspec

            platforms:
              - name: ubuntu-20.04
              - name: centos-8

            suites:
              - name: default
                verifier:
                  inspec_tests:
                    - test/integration/default
          KITCHEN_YML
        end

      end

      include_examples "chefspec_spec_helper_file" do
        let(:argv) { %w{ new_cookbook --policy --specs } }

        let(:expected_chefspec_spec_helper_content) do
          <<~SPEC_HELPER
            require 'chefspec'
            require 'chefspec/policyfile'
          SPEC_HELPER
        end

      end

    end

    context "when YAML recipe flag is passed" do

      let(:argv) { %w{new_cookbook --yaml} }

      describe "recipes/default.yml" do
        let(:file) { File.join(tempdir, "new_cookbook", "recipes", "default.yml") }

        let(:expected_content_header) do
          <<~DEFAULT_YML_HEADER
          #
          # Cookbook:: new_cookbook
          # Recipe:: default
          #
          DEFAULT_YML_HEADER
        end

        let(:expected_content) do
          <<~DEFAULT_YML_CONTENT
          ---
          resources:
          # Example Syntax
          # Additional snippets are available using the Chef Infra Extension for Visual Studio Code
          # - type: file
          #   name: '/path/to/file'
          #   content: 'content'
          #   owner: 'root'
          #   group: 'root'
          #   mode: '0755'
          #   action:
          #     - create
          DEFAULT_YML_CONTENT
        end

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "has a default.yml file with template contents" do
          expect(IO.read(file)).to match(expected_content_header)
          expect(IO.read(file)).to match(expected_content)
        end

      end

    end

    context "when configured for Berkshelf" do

      let(:argv) { %w{new_cookbook --berks} }

      describe "Berksfile" do

        let(:file) { File.join(tempdir, "new_cookbook", "Berksfile") }

        let(:expected_content) do
          <<~POLICYFILE_RB
            source 'https://supermarket.chef.io'

            metadata
          POLICYFILE_RB
        end

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "pulls deps from metadata" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      include_examples "kitchen_yml_and_integration_tests" do

        let(:expected_kitchen_yml_content) do
          <<~KITCHEN_YML
            ---
            driver:
              name: vagrant

            ## The forwarded_port port feature lets you connect to ports on the VM guest via
            ## localhost on the host.
            ## see also: https://www.vagrantup.com/docs/networking/forwarded_ports

            #  network:
            #    - ["forwarded_port", {guest: 80, host: 8080}]

            provisioner:
              name: chef_zero
              # You may wish to disable always updating cookbooks in CI or other testing environments.
              # For example:
              #   always_update_cookbooks: <%= !ENV['CI'] %>
              always_update_cookbooks: true

              ## product_name and product_version specifies a specific Chef product and version to install.
              ## see the Chef documentation for more details: https://docs.chef.io/workstation/config_yml_kitchen/
              #  product_name: chef
              #  product_version: 17

            verifier:
              name: inspec

            platforms:
              - name: ubuntu-20.04
              - name: centos-8

            suites:
              - name: default
                run_list:
                  - recipe[new_cookbook::default]
                verifier:
                  inspec_tests:
                    - test/integration/default
                attributes:
          KITCHEN_YML
        end

      end

      include_examples "chefspec_spec_helper_file" do
        let(:argv) { %w{ new_cookbook --berks --specs } }

        let(:expected_chefspec_spec_helper_content) do
          <<~SPEC_HELPER
            require 'chefspec'
            require 'chefspec/berkshelf'
          SPEC_HELPER
        end

      end

    end

    describe "metadata.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "metadata.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { /name\s+'new_cookbook'.+# issues_url.+# source_url/m }
      end
    end

    describe "recipes/default.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "recipes", "default.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# Cookbook:: new_cookbook" }
      end
    end

    describe "spec/unit/recipes/default_spec.rb" do
      let(:argv) { %w{ new_cookbook --specs } }
      let(:file) { File.join(tempdir, "new_cookbook", "spec", "unit", "recipes", "default_spec.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "describe 'new_cookbook::default' do" }
      end
    end

  end

  context "when given the path to the cookbook to generate" do
    let(:argv) { [ File.join(tempdir, "a_new_cookbook") ] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(tempdir)
      expect(generator_context.cookbook_name).to eq("a_new_cookbook")
    end

  end

  context "when given generic arguments to populate the generator context" do
    let(:argv) { [ "new_cookbook", "--generator-arg", "key1=value1", "-a", "key2=value2", "-a", " key3 = value3 " ] }

    before do
      reset_tempdir
    end

    it "configures the generator context for long form option key1" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key1).to eq("value1")
    end

    it "configures the generator context for short form option key2" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key2).to eq("value2")
    end

    it "configures the generator context for key3 containing additional spaces" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key3).to eq("value3")
    end

  end

end
