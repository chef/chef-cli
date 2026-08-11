#
# Copyright:: (c) 2019-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef-cli/command/gem"

describe ChefCLI::Command::GemForwarder do
  let(:command_instance) { described_class.new }
  let(:gem_runner) { instance_double(Gem::GemRunner) }
  let(:ruby_version) { RbConfig::CONFIG["ruby_version"] }
  let(:expected_gem_dir) { File.expand_path("~/.chef/ruby/#{ruby_version}/gems") }

  before do
    allow(Gem::GemRunner).to receive(:new).and_return(gem_runner)
  end

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef gem GEM_COMMANDS_AND_OPTIONS")
  end

  describe "#needs_version?" do
    it "returns false to let GemRunner handle version flag" do
      expect(command_instance.needs_version?([])).to be(false)
    end

    it "returns false even with -v parameter" do
      expect(command_instance.needs_version?(["-v"])).to be(false)
    end
  end

  describe "#run" do
    context "when NOT in a Habitat environment" do
      before do
        allow(command_instance).to receive(:habitat_install?).and_return(false)
        allow(ENV).to receive(:[]).with("CHEF_GEM_HOME_ENABLED").and_return(nil)
      end

      it "forwards params to Gem::GemRunner" do
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        expect(command_instance.run(%w(install knife))).to eq(true)
      end

      it "does not modify GEM_HOME" do
        expect(gem_runner).to receive(:run).with(%w(list)).and_return(true)
        expect(ENV).not_to receive(:[]=).with("GEM_HOME", anything)
        command_instance.run(%w(list))
      end

      it "returns true when GemRunner returns nil" do
        expect(gem_runner).to receive(:run).with(%w(list)).and_return(nil)
        expect(command_instance.run(%w(list))).to eq(true)
      end
    end

    context "when in a Habitat environment" do
      let(:vendor_dir) { "/hab/pkgs/chef/chef-cli/1.0.0/123/vendor" }
      let(:existing_gem_path) { "#{expected_gem_dir}#{File::PATH_SEPARATOR}#{vendor_dir}" }

      before do
        allow(command_instance).to receive(:habitat_install?).and_return(true)
        allow(ENV).to receive(:[]).with("CHEF_GEM_HOME_ENABLED").and_return("true")
        allow(command_instance).to receive(:habitat_user_gem_dir).and_return(expected_gem_dir)
        allow(ENV).to receive(:[]).with("GEM_PATH").and_return(existing_gem_path)
        allow(Dir).to receive(:exist?).with(expected_gem_dir).and_return(true)
        allow(Gem).to receive(:clear_paths)
      end

      it "sets GEM_HOME to user gem directory" do
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        expect(ENV).to receive(:[]=).with("GEM_HOME", expected_gem_dir)
        allow(ENV).to receive(:[]=).with("GEM_PATH", anything)
        command_instance.run(%w(install knife))
      end

      it "sets GEM_PATH to include both user gem dir and existing GEM_PATH" do
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        allow(ENV).to receive(:[]=).with("GEM_HOME", expected_gem_dir)
        expected_gem_path = "#{expected_gem_dir}#{File::PATH_SEPARATOR}#{existing_gem_path}"
        expect(ENV).to receive(:[]=).with("GEM_PATH", expected_gem_path)
        command_instance.run(%w(install knife))
      end

      it "clears Gem paths after setting environment" do
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        allow(ENV).to receive(:[]=)
        expect(Gem).to receive(:clear_paths)
        command_instance.run(%w(install knife))
      end

      it "creates the gem directory if it doesn't exist" do
        allow(Dir).to receive(:exist?).with(expected_gem_dir).and_return(false)
        expect(FileUtils).to receive(:mkdir_p).with(expected_gem_dir)
        allow(ENV).to receive(:[]=)
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        command_instance.run(%w(install knife))
      end

      it "does not create the gem directory if it already exists" do
        allow(Dir).to receive(:exist?).with(expected_gem_dir).and_return(true)
        expect(FileUtils).not_to receive(:mkdir_p)
        allow(ENV).to receive(:[]=)
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        command_instance.run(%w(install knife))
      end

      it "forwards all gem subcommands correctly" do
        allow(ENV).to receive(:[]=)
        %w(install list uninstall source search update).each do |subcmd|
          expect(gem_runner).to receive(:run).with([subcmd]).and_return(true)
          expect(command_instance.run([subcmd])).to eq(true)
        end
      end
    end

    context "when CHEF_GEM_HOME_ENABLED is set but habitat_install? is false" do
      before do
        allow(command_instance).to receive(:habitat_install?).and_return(false)
        allow(ENV).to receive(:[]).with("CHEF_GEM_HOME_ENABLED").and_return("true")
        allow(command_instance).to receive(:habitat_user_gem_dir).and_return(expected_gem_dir)
        allow(ENV).to receive(:[]).with("GEM_PATH").and_return(nil)
        allow(Dir).to receive(:exist?).with(expected_gem_dir).and_return(true)
        allow(Gem).to receive(:clear_paths)
      end

      it "still sets up gem environment via env var detection" do
        expect(gem_runner).to receive(:run).with(%w(install knife)).and_return(true)
        expect(ENV).to receive(:[]=).with("GEM_HOME", expected_gem_dir)
        allow(ENV).to receive(:[]=).with("GEM_PATH", anything)
        command_instance.run(%w(install knife))
      end
    end

    context "when GemRunner raises Gem::SystemExitException" do
      before do
        allow(command_instance).to receive(:habitat_install?).and_return(false)
        allow(ENV).to receive(:[]).with("CHEF_GEM_HOME_ENABLED").and_return(nil)
      end

      it "exits with the exception's exit code" do
        exception = Gem::SystemExitException.new(1)
        allow(gem_runner).to receive(:run).and_raise(exception)
        expect { command_instance.run(%w(install bad_gem)) }.to raise_error(SystemExit) { |e|
          expect(e.status).to eq(1)
        }
      end
    end
  end

  describe "#habitat_user_gem_dir" do
    it "returns ~/.chef/ruby/<version>/gems path" do
      expect(command_instance.send(:habitat_user_gem_dir)).to eq(expected_gem_dir)
    end

    it "uses the ruby_version from RbConfig" do
      allow(RbConfig::CONFIG).to receive(:[]).with("ruby_version").and_return("3.3.0")
      expect(command_instance.send(:habitat_user_gem_dir)).to eq(
        File.expand_path("~/.chef/ruby/3.3.0/gems")
      )
    end
  end
end
