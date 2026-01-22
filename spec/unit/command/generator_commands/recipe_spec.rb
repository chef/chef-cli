#
#  Copyright (c) 2019-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "shared/a_file_generator"
require "chef-cli/command/generator_commands/recipe"

describe ChefCLI::Command::GeneratorCommands::Recipe do

  include_examples "a file generator" do

    let(:generator_name) { "recipe" }
    let(:generated_files) do
      [ "recipes/new_recipe.rb",
                              "spec/spec_helper.rb",
                              "spec/unit/recipes/new_recipe_spec.rb",
                              "test/integration/default/new_recipe_test.rb",
                            ]
    end
    let(:new_file_name) { "new_recipe" }

  end

  context "when YAML recipe flag is passed" do

    let(:argv) { %w{some_recipe --yaml} }
    let(:expected_cookbook_root) { tempdir }
    let(:cookbook_name) { "example_cookbook" }
    let(:cookbook_path) { File.join(tempdir, cookbook_name) }

    let(:generator_name) { "recipe" }
    let(:generated_files) do
      [ "recipes/some_recipe.yml",
                              "spec/spec_helper.rb",
                              "spec/unit/recipes/some_recipe_spec.rb",
                              "test/integration/default/some_recipe_test.rb",
                            ]
    end
    let(:new_file_name) { "some_recipe" }

    before do
      FileUtils.cp_r(File.join(fixtures_path, "example_cookbook"), tempdir)
    end

    it "creates a new recipe" do
      Dir.chdir(cookbook_path) do
        allow(recipe_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        recipe_generator.run
      end

      generated_files.each do |expected_file|
        expect(File).to exist(File.join(cookbook_path, expected_file))
      end
    end

  end

end
