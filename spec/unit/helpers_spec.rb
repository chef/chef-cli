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
require "chef-cli/helpers"

describe ChefCLI::Helpers do
  context "path_check!" do
    let(:ruby_path) { "/opt/chef-workstation/embedded/bin/ruby" }

    before do
      allow(Gem).to receive(:ruby).and_return(ruby_path)
    end

    context "when installed via omnibus" do
      before do
        allow(ChefCLI::Helpers).to receive(:omnibus_install?).and_return true
      end

      context "on unix" do

        let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }
        let(:omnibus_embedded_bin_dir) { "/opt/chef-workstation/embedded/bin" }
        let(:omnibus_bin_dir) { "/opt/chef-workstation/bin" }
        let(:expected_PATH) { [ omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"].split(File::PATH_SEPARATOR) ] }
        let(:expected_GEM_ROOT) { Gem.default_dir }
        let(:expected_GEM_HOME) { Gem.user_dir }
        let(:expected_GEM_PATH) { Gem.path.join(File::PATH_SEPARATOR) }


        it "#omnibus_env path" do
          allow(ChefCLI::Helpers).to receive(:omnibus_bin_dir).and_return("/opt/chef-workstation/bin")
          allow(ChefCLI::Helpers).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chef-workstation/embedded/bin")
          allow(ChefCLI::Helpers).to receive(:omnibus_env).and_return(
            "PATH" => expected_PATH.flatten.uniq.join(File::PATH_SEPARATOR),
            "GEM_ROOT" => expected_GEM_ROOT,
            "GEM_HOME" => expected_GEM_HOME,
            "GEM_PATH" => expected_GEM_PATH
          )
        end
      end

      context "on windows" do
        let(:ruby_path) { "c:/opscode/chef-workstation/embedded/bin/ruby.exe" }
        let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }
        let(:omnibus_embedded_bin_dir) { "c:/opscode/chef-workstation/embedded/bin" }
        let(:omnibus_bin_dir) { "c:/opscode/chef-workstation/bin" }
        let(:expected_GEM_ROOT) { Gem.default_dir }
        let(:expected_GEM_HOME) { Gem.user_dir }
        let(:expected_GEM_PATH) { Gem.path.join(File::PATH_SEPARATOR) }
        let(:omnibus_root) { "c:/opscode/chef-workstation" }
        let(:expected_PATH) { [ omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"].split(File::PATH_SEPARATOR) ] }

        before do
          allow(ChefCLI::Helpers).to receive(:expected_omnibus_root).and_return(ruby_path)
          allow(ChefCLI::Helpers).to receive(:omnibus_install?).and_return(true)
          allow(Chef::Platform).to receive(:windows?).and_return(true)
        end

        it "#omnibus_env path" do
          allow(ChefCLI::Helpers).to receive(:omnibus_bin_dir).and_return("c:/opscode/chef-workstation/bin")
          allow(ChefCLI::Helpers).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chef-workstation/embedded/bin")
          allow(ChefCLI::Helpers).to receive(:omnibus_env).and_return(
            "PATH" => expected_PATH.flatten.uniq.join(File::PATH_SEPARATOR),
            "GEM_ROOT" => expected_GEM_ROOT,
            "GEM_HOME" => expected_GEM_HOME,
            "GEM_PATH" => expected_GEM_PATH
          )
        end
      end
    end

    context "when not installed via omnibus" do

      before do
        allow(ChefCLI::Helpers).to receive(:omnibus_install?).and_return false
      end
      let(:ruby_path) { "/Users/bog/.lots_o_rubies/2.1.2/bin/ruby" }
      let(:expected_root_path) { "/Users/bog/.lots_o_rubies" }

      before do
        allow(File).to receive(:exist?).with(expected_root_path).and_return(false)

        %i{
          omnibus_root
          omnibus_bin_dir
          omnibus_embedded_bin_dir
        }.each do |method_name|
          allow(ChefCLI::Helpers).to receive(method_name).and_raise(ChefCLI::OmnibusInstallNotFound.new)
        end
      end

      it "skips the sanity check without error" do

      end

    end

    context "when installed with habitat" do
      let(:chef_dke_path) { "/hab/pkgs/chef/chef-workstation/1.0.0/123" }
      let(:cli_hab_path) { "/hab/pkgs/chef/chef-cli/1.0.0/123" }
      let(:expected_gem_root) { Gem.default_dir }
      let(:expected_path) { [File.join(chef_dke_path, "bin"), File.join(cli_hab_path, "vendor", "bin"), "/usr/bin:/bin"].flatten }
      let(:expected_env) do
        {
          "PATH" => expected_path.join(File::PATH_SEPARATOR),
          "GEM_ROOT" => expected_gem_root,
          "GEM_HOME" => "#{cli_hab_path}/vendor",
          "GEM_PATH" => "#{cli_hab_path}/vendor",
        }
      end

      before do
        allow(ChefCLI::Helpers).to receive(:habitat_chef_dke?).and_return true
        allow(ChefCLI::Helpers).to receive(:habitat_standalone?).and_return false
        allow(ENV).to receive(:[]).with("PATH").and_return("/usr/bin:/bin")
        allow(ENV).to receive(:[]).with("CHEF_CLI_VERSION").and_return(nil)
        allow(Dir).to receive(:exist?).with("#{cli_hab_path}/vendor").and_return(true) # <-- Add this line
      end

      it "should return the habitat env" do
        allow(ChefCLI::Helpers).to receive(:fetch_chef_cli_version_pkg).and_return(nil) # Ensure no version override
        expect(ChefCLI::Helpers).to receive(:get_pkg_prefix).with("chef/chef-workstation").and_return(chef_dke_path)
        expect(ChefCLI::Helpers).to receive(:get_pkg_prefix).with("chef/chef-cli").and_return(cli_hab_path)

        expect(ChefCLI::Helpers.habitat_env).to eq(expected_env)
      end
    end

  end
end
