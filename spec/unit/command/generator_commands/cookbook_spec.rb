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

    it "warns if a hyphenated cookbook name is passed" do
      expect(with_argv(%w{my-cookbook}).run).to eq(1)
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

    context "when given the specs flag" do

      let(:argv) { %w{ new_cookbook --specs } }

      it "configures the generator context with specs mode enabled" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.specs).to be(true)
      end
    end

    context "when given the verbose flag" do

      let(:argv) { %w{ new_cookbook --verbose } }

      it "configures the generator context with verbose mode enabled" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.verbose).to be(true)
      end
    end

    shared_examples_for "a generated file" do |context_var|
      before do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(1)
        end
      end

      it "should not generate a file" do
        expect(File.directory?(file)).to be false
        expect(File).not_to exist(file)
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
