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
autoload :YAML, "yaml"
require "chef-cli/command/env"

describe ChefCLI::Command::Env do
  let(:ui) { TestHelpers::TestUI.new }
  let(:command_instance) { ChefCLI::Command::Env.new }

  let(:command_options) { [] }

  let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }
  let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }
  let(:omnibus_bin_dir) { "/foo/bin" }

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef env")
  end

  describe "when running from within an omnibus install" do
    before do
      allow(command_instance).to receive(:habitat_install?).and_return false
      allow(command_instance).to receive(:omnibus_install?).and_return true
      allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
      allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      allow(command_instance).to receive(:get_product_info).and_return(ChefCLI::Dist::PRODUCT)
      command_instance.ui = ui
    end

    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
      before :each do
        run_command
      end
      it "output should be valid yaml" do
        expect { yaml }.not_to raise_error
      end
      it "should include correct Workstation version info" do
        expect(yaml).to have_key ChefCLI::Dist::PRODUCT
        expect(yaml[ChefCLI::Dist::PRODUCT]["Version"]).to eql ChefCLI::VERSION
      end
    end
  end
  describe "when running locally" do
    before do
      allow(command_instance).to receive(:habitat_install?).and_return false
      allow(command_instance).to receive(:omnibus_install?).and_return false
      command_instance.ui = ui
    end

    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
      before :each do
        run_command
      end
      it "output should be valid yaml" do
        expect { yaml }.not_to raise_error
      end
      it "Workstation version should indicate that that we're not running from a WS install" do
        expect(yaml).to have_key ChefCLI::Dist::PRODUCT
        expect(yaml[ChefCLI::Dist::PRODUCT]["Version"]).to eql "Not running from within Workstation"
      end
      it "should return valid yaml" do
        run_command
        expect { YAML.load(ui.output) }.not_to raise_error
      end
    end
  end

  describe "when running in a Chef-cli Habitat Standalone package" do
    before do
      allow(command_instance).to receive(:habitat_install?).and_return(true)
      allow(command_instance).to receive(:habitat_standalone?).and_return(true)
      allow(command_instance).to receive(:habitat_chef_dke?).and_return(false)
      allow(command_instance).to receive(:omnibus_install?).and_return(false) # Ensure Omnibus is NOT detected
      allow(command_instance).to receive(:get_product_info).and_return(ChefCLI::Dist::CHEF_CLI_PACKAGE)
  
      # Habitat package paths
      hab_pkg_path = "/hab/pkgs/chef/chef-cli/1.0.0/20240210120000"
      allow(command_instance).to receive(:get_chef_cli_path).and_return("#{hab_pkg_path}")

      # Mock habitat_env to reflect correct GEM paths
      allow(command_instance).to receive(:habitat_env).and_return({
        "GEM_ROOT" => "/hab/pkgs/core/ruby/3.1.0/20240101000000/lib/ruby/gems",
        "GEM_HOME" => "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0",
        "GEM_PATH" => "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0",
        "PATH" => "/hab/pkgs/chef/chef-cli/1.0.0/20240210120000/bin:/usr/local/bin:/usr/bin"
      })
  
      command_instance.ui = ui
    end
  
    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
      
      before :each do
        run_command
      end
  
      it "should include correct chef-cli hab pkg name" do
        expect(yaml).to have_key(ChefCLI::Dist::CHEF_CLI_PACKAGE)
      end
  
      it "should include correct chef-cli hab pkg version info" do
        expect(yaml[ChefCLI::Dist::CHEF_CLI_PACKAGE]["Version"]).to eql ChefCLI::VERSION
      end
  
      it "should include correct Habitat installation path" do
        expect(yaml[ChefCLI::Dist::CHEF_CLI_PACKAGE]["Install Directory"]).to eql "/hab/pkgs/chef/chef-cli/1.0.0/20240210120000"
      end

      it "should include correct GEM_ROOT path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM ROOT"]).to eql "/hab/pkgs/core/ruby/3.1.0/20240101000000/lib/ruby/gems"
      end
  
      it "should include correct GEM_HOME path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM HOME"]).to eql "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0"
      end
  
      it "should include correct GEM_PATH paths" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM PATHS"]).to eql ["/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0"]
      end
    end
  end
    
  describe "when running chef-cli coming with Habitat Chef-DKE package" do
    before do
      # Mock all Habitat-related methods
      allow(command_instance).to receive(:habitat_install?).and_return true
      allow(command_instance).to receive(:habitat_chef_dke?).and_return true
      allow(command_instance).to receive(:habitat_standalone?).and_return false
      allow(command_instance).to receive(:omnibus_install?).and_return false
      allow(command_instance).to receive(:get_product_info).and_return(ChefCLI::Dist::CHEF_DK_CLI_PACKAGE)

      # Habitat package paths
      hab_pkg_path = "/hab/pkgs/chef/chef-development-kit-enterprise/1.0.0/20240210120000"
      allow(command_instance).to receive(:get_chef_cli_path).and_return("#{hab_pkg_path}")

      # Mock habitat_env to reflect correct GEM paths
      allow(command_instance).to receive(:habitat_env).and_return({
        "GEM_ROOT" => "/hab/pkgs/core/ruby/3.1.0/20240101000000/lib/ruby/gems",
        "GEM_HOME" => "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0",
        "GEM_PATH" => "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0",
        "PATH" => "/hab/pkgs/chef/chef-development-kit-enterprise/1.0.0/20240210120000/bin:/usr/local/bin:/usr/bin"
      })
      
      command_instance.ui = ui
      end
  
    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
  
      before :each do
        run_command
      end
  
      it "should include correct product name for Chef-DKE Habitat package" do
        expect(yaml).to have_key(ChefCLI::Dist::CHEF_DK_CLI_PACKAGE)
      end

      it "should include correct version" do
        expect(yaml[ChefCLI::Dist::CHEF_DK_CLI_PACKAGE]["Version"]).to eql ChefCLI::VERSION
      end
  
      it "should include correct Habitat installation path" do
        expect(yaml[ChefCLI::Dist::CHEF_DK_CLI_PACKAGE]["Install Directory"]).to eql "/hab/pkgs/chef/chef-development-kit-enterprise/1.0.0/20240210120000"
      end

      it "should include correct GEM_ROOT path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM ROOT"]).to eql "/hab/pkgs/core/ruby/3.1.0/20240101000000/lib/ruby/gems"
      end
  
      it "should include correct GEM_HOME path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM HOME"]).to eql "/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0"
      end
  
      it "should include correct GEM_PATH paths" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM PATHS"]).to eql ["/hab/pkgs/chef/chef-cli/1.0.0/20240210121000/vendor/bundle/ruby/3.1.0"]
      end

    end
  end

  def run_command
    command_instance.run_with_default_options(false, command_options)
  end

end
