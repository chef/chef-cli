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
require "shared/a_file_generator"
require "chef-cli/command/generator_commands/waiver"

describe ChefCLI::Command::GeneratorCommands::Waiver do

  include_examples "a file generator" do

    let(:generator_name) { "waiver" }
    let(:generated_files) { [ "compliance/waivers/new_waiver.yml" ] }
    let(:new_file_name) { "new_waiver" }

  end
end
