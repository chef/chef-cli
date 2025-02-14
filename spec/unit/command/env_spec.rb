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
    let(:standalone_pkg_base) { "/hab/pkgs/chef/chef-cli" }
    let(:standalone_pkg_version) { "1.0.0" }
    let(:standalone_pkg_build) { "20240210120000" }
    let(:standalone_pkg_path) { "#{standalone_pkg_base}/#{standalone_pkg_version}/#{standalone_pkg_build}" }

    let(:ruby_version) { "3.1.0" }
    let(:ruby_base) { "/hab/pkgs/core/ruby/#{ruby_version}/20240101000000/lib/ruby/gems" }
    let(:cli_gem_home) { "/hab/pkgs/chef/chef-cli/#{standalone_pkg_version}/20240210121000/vendor/bundle/ruby/#{ruby_version}" }

    before do
      allow(command_instance).to receive(:habitat_install?).and_return(true)
      allow(command_instance).to receive(:habitat_standalone?).and_return(true)
      allow(command_instance).to receive(:habitat_chef_dke?).and_return(false)
      allow(command_instance).to receive(:omnibus_install?).and_return(false)
      allow(command_instance).to receive(:get_product_info).and_return(ChefCLI::Dist::CHEF_CLI_PACKAGE)
  
      allow(command_instance).to receive(:get_pkg_install_path).and_return(standalone_pkg_path)

      allow(command_instance).to receive(:habitat_env).and_return({
        "GEM_ROOT" => ruby_base,
        "GEM_HOME" => cli_gem_home,
        "GEM_PATH" => cli_gem_home,
        "PATH" => "#{standalone_pkg_path}/bin:/usr/local/bin:/usr/bin"
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
        expect(yaml[ChefCLI::Dist::CHEF_CLI_PACKAGE]["Install Directory"]).to eql standalone_pkg_path
      end

      it "should include correct GEM_ROOT path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM ROOT"]).to eql ruby_base
      end
  
      it "should include correct GEM_HOME path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM HOME"]).to eql cli_gem_home
      end
  
      it "should include correct GEM_PATH paths" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM PATHS"]).to eql [cli_gem_home]
      end
    end
  end

  describe "when running chef-cli coming with Chef-DKE Habitat package" do
    let(:hab_pkg_base) { "/hab/pkgs/chef/chef-development-kit-enterprise" }
    let(:hab_pkg_version) { "1.0.0" }
    let(:hab_pkg_build) { "20240210120000" }
    let(:hab_pkg_path) { "#{hab_pkg_base}/#{hab_pkg_version}/#{hab_pkg_build}" }

    let(:ruby_version) { "3.1.0" }
    let(:ruby_base) { "/hab/pkgs/core/ruby/#{ruby_version}/20240101000000/lib/ruby/gems" }
    let(:cli_gem_home) { "/hab/pkgs/chef/chef-cli/#{hab_pkg_version}/20240210121000/vendor/bundle/ruby/#{ruby_version}" }

    before do
      # Mock all Habitat-related methods
      allow(command_instance).to receive(:habitat_install?).and_return true
      allow(command_instance).to receive(:habitat_chef_dke?).and_return true
      allow(command_instance).to receive(:habitat_standalone?).and_return false
      allow(command_instance).to receive(:omnibus_install?).and_return false
      allow(command_instance).to receive(:get_product_info).and_return(ChefCLI::Dist::CHEF_DK_CLI_PACKAGE)

      # Mock Habitat package paths
      allow(command_instance).to receive(:get_pkg_install_path).and_return(hab_pkg_path)

      # Mock habitat_env to reflect correct GEM paths
      allow(command_instance).to receive(:habitat_env).and_return({
        "GEM_ROOT" => ruby_base,
        "GEM_HOME" => cli_gem_home,
        "GEM_PATH" => cli_gem_home,
        "PATH" => "#{hab_pkg_path}/bin:/usr/local/bin:/usr/bin"
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
        expect(yaml[ChefCLI::Dist::CHEF_DK_CLI_PACKAGE]["Install Directory"]).to eql hab_pkg_path
      end

      it "should include correct GEM_ROOT path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM ROOT"]).to eql ruby_base
      end
  
      it "should include correct GEM_HOME path" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM HOME"]).to eql cli_gem_home
      end
  
      it "should include correct GEM_PATH paths" do
        expect(yaml["Ruby"]["RubyGems"]["Gem Environment"]["GEM PATHS"]).to eql [cli_gem_home]
      end
    end
  end

  def run_command
    command_instance.run_with_default_options(false, command_options)
  end

end
