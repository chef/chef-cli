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
require "chef-cli/helpers"

describe ChefCLI::Helpers do
  context "path_check!" do

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
        let(:ruby_path) { "/opt/chef-workstation/embedded/bin/ruby" }

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
  end
end
