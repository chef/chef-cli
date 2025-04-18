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
require "chef-cli/policyfile_services/install"

describe ChefCLI::PolicyfileServices::Install do

  include ChefCLI::Helpers

  let(:working_dir) do
    path = File.join(tempdir, "policyfile_services_test_working_dir")
    Dir.mkdir(path)
    path
  end

  let(:policyfile_rb_explicit_name) { nil }

  let(:policyfile_rb_name) { policyfile_rb_explicit_name || "Policyfile.rb" }

  let(:policyfile_lock_name) { "Policyfile.lock.json" }

  let(:policyfile_rb_path) { File.join(working_dir, policyfile_rb_name) }

  let(:policyfile_lock_path) { File.join(working_dir, policyfile_lock_name) }

  let(:local_cookbooks_root) do
    File.join(fixtures_path, "local_path_cookbooks")
  end

  let(:policyfile_content) do
    <<~E
      name 'install-example'

      run_list 'local-cookbook'

      cookbook 'local-cookbook', path: '#{local_cookbooks_root}/local-cookbook'
    E
  end

  let(:overwrite) { false }

  let(:cookbooks_to_update) { [] || [ "my_cookbook" ] }

  let(:cookbooks_to_update_empty) { false }

  let(:ui) { TestHelpers::TestUI.new }

  let(:install_service) { described_class.new(policyfile: policyfile_rb_name, ui: ui, root_dir: working_dir, overwrite: overwrite) }

  let(:storage_config) do
    ChefCLI::Policyfile::StorageConfig.new( cache_path: nil, relative_paths_root: local_cookbooks_root )
  end

  def result_policyfile_lock
    expect(File).to exist(policyfile_lock_path)
    content = File.read(policyfile_lock_path)
    lock_data = FFI_Yajl::Parser.parse(content)
    ChefCLI::PolicyfileLock.new(storage_config).build_from_lock_data(lock_data)
  end

  context "when no Policyfile is present or specified" do

    it "errors out" do
      expect { install_service.run }.to raise_error(ChefCLI::PolicyfileNotFound, "Policyfile not found at path #{policyfile_rb_path}")
    end

  end

  context "When an explicit Policfyfile lock name is given and does not exist" do

    let(:policyfile_rb_explicit_name) { "i_do_not_exist.lock.json" }

    it "errors out" do
      expect { install_service.run }.to raise_error(ChefCLI::PolicyfileNotFound, "Policyfile lock not found at path #{policyfile_rb_path}")
    end

  end

  context "When an explicit Policfyfile name is given and does not exist" do

    let(:policyfile_rb_explicit_name) { "i_do_not_exist.rb" }

    it "errors out" do
      expect { install_service.run }.to raise_error(ChefCLI::PolicyfileNotFound, "Policyfile not found at path #{policyfile_rb_path}")
    end

  end

  context "when a Policyfile exists" do

    before do
      with_file(policyfile_rb_path) { |f| f.print(policyfile_content) }
    end

    it "infers that the Policyfile.rb is located at $CWD/Policyfile.rb" do
      expect(install_service.policyfile_expanded_path).to eq(policyfile_rb_path)
    end

    it "reads the policyfile from disk" do
      expect(install_service.policyfile_content).to eq(policyfile_content)
    end

    context "and the policyfile has an error" do

      let(:policyfile_content) { 'raise "borkbork"' }

      it "errors out and creates no lockfile" do
        expect { install_service.run }.to raise_error(ChefCLI::PolicyfileInstallError)
        expect(File).to_not exist(policyfile_lock_path)
      end

    end

    context "and no lockfile exists" do

      it "solves the Policyfile demands, installs cookbooks, emits a lockfile" do
        install_service.run
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "prints the policy name" do
        install_service.run
        expect(ui.output).to include("Building policy install-example")
      end

      it "prints the expanded run list" do
        install_service.run
        expect(ui.output).to include("Expanded run list: recipe[local-cookbook]")
      end

      it "prints the lockfile path" do
        install_service.run
        expect(ui.output).to include("Lockfile written to #{working_dir}/Policyfile.lock.json")
      end

      it "prints the lockfile's revision id" do
        install_service.run
        expect(ui.output).to include("Policy revision id: 7da81d2c7bb97f904637f97e7f8b487fa4bb1ed682edea7087743dec84c254ec")
      end

    end

    context "when cookbook to update is empty and no policy lock exist" do

      let(:cookbooks_to_update_empty) { true }

      it "create the policy lock" do
        install_service.run(:cookbooks_to_update)
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "checks for policy lock" do
        lock = install_service.policyfile_lock
        expect(lock).to eq(nil)
      end

    end

    context "when cookbook to update is empty and policy lock exist" do

      before do
        install_service.dup.run
      end

      let(:cookbooks_to_update_empty) { true }

      it "create the policy lock" do
        install_service.run(:cookbooks_to_update)
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "checks for policy lock" do
        lock = install_service.policyfile_lock
        expect(lock).to be_an_instance_of(ChefCLI::PolicyfileLock)
        expect(lock.name).to eq("install-example")
        expect(lock.cookbook_locks).to have_key("local-cookbook")
      end

    end

    context "when cookbook to update is not empty and no policy lock exist" do

      let(:cookbooks_to_update) { [ "my_cookbook" ] }

      it "create the policy lock" do
        install_service.run(:cookbooks_to_update)
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "checks for policy lock" do
        lock = install_service.policyfile_lock
        expect(lock).to eq(nil)
      end

    end

    context "when cookbook to update is not empty and policy lock exist" do

      before do
        install_service.dup.run
      end

      let(:cookbooks_to_update) { [ "my_cookbook" ] }

      it "create the policy lock" do
        install_service.run(:cookbooks_to_update)
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "create the policy lock" do
        lock = install_service.policyfile_lock
        expect(lock).to be_an_instance_of(ChefCLI::PolicyfileLock)
        expect(lock.name).to eq("install-example")
        expect(lock.cookbook_locks).to have_key("local-cookbook")
      end

    end

    context "and a lockfile exists and `overwrite` is specified" do

      let(:overwrite) { true }

      before do
        File.binwrite(policyfile_lock_path, "This is the old lockfile content")
      end

      it "solves the Policyfile demands, installs cookbooks, emits a lockfile" do
        install_service.run
        generated_lock = result_policyfile_lock
        expect(generated_lock.name).to eq("install-example")
        expect(generated_lock.cookbook_locks).to have_key("local-cookbook")
      end

    end

    context "and a lockfile exists" do

      before do
        install_service.dup.run
      end

      it "reads the policyfile lock from disk" do
        lock = install_service.policyfile_lock
        expect(lock).to be_an_instance_of(ChefCLI::PolicyfileLock)
        expect(lock.name).to eq("install-example")
        expect(lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "ensures that cookbooks are installed" do
        expect(install_service.policyfile_lock).to receive(:install_cookbooks).and_call_original
        install_service.run
      end

      describe "when an error occurs during the install" do

        before do
          expect(install_service.policyfile_lock).to receive(:install_cookbooks).and_raise("some error")
        end

        it "raises a PolicyfileInstallError" do
          expect { install_service.run }.to raise_error(ChefCLI::PolicyfileInstallError)
        end

      end

      context "and the Policyfile has updated dependendencies" do

        # For very first iteration, we won't tackle this case if it's hard
        it "Conservatively updates deps, recomputes lock, and installs"

      end

    end

    context "and an explicit Policyfile name is given" do

      let(:policyfile_rb_explicit_name) { "MyPolicy.rb" }

      let(:policyfile_lock_name) { "MyPolicy.lock.json" }

      it "infers that the Policyfile.rb is located at $CWD/$POLICYFILE_NAME" do
        expect(install_service.policyfile_expanded_path).to eq(policyfile_rb_path)
      end

      it "reads the policyfile from disk" do
        expect(install_service.policyfile_content).to eq(policyfile_content)
      end

    end
  end

end
