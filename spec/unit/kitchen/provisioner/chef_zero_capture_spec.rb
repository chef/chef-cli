#
# Author:: Marc Paradsie <marc.paradise@gmail.com>
#
# Copyright (c) 2019-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../../../spec_helper"

require "kitchen"
require "kitchen/provisioner/chef_zero_capture"

describe Kitchen::Provisioner::ChefZeroCapture do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:kitchen_root) { Dir.mktmpdir }

  let(:config) do
    { test_base_path: "/t", base_path: "/b", kitchen_root: kitchen_root, root_path: kitchen_root }
  end
  let(:platform)        { double("platform", os_type: nil) }
  let(:suite)           { double("suite", name: "fried") }

  let(:instance_config) do
    double("config", name: "coolbeans", logger: logger, suite: suite, platform: platform)
  end

  subject do
    p = Kitchen::Provisioner::ChefZeroCapture.new(config)
    p.finalize_config!(instance_config)
  end

  after do
    FileUtils.remove_entry(kitchen_root)
  end

  describe "#create_sandbox" do
    let(:sandbox_mock) do
      double("sandbox", populate: nil)
    end
    before do
      allow(Kitchen::Provisioner::ChefZeroCaptureSandbox).to receive(:new).and_return sandbox_mock
    end

    it "initializes files and populates a ChefZeroCaptureSandbox" do
      expect(subject).to receive(:prepare_validation_pem)
      expect(subject).to receive(:prepare_config_rb)
      expect(sandbox_mock).to receive(:populate)
      subject.create_sandbox
    end

    after do
      begin
        subject.cleanup_sandbox
      rescue # rubocop:disable Lint/HandleExceptions
      end
    end
  end

  describe "#default_config_rb" do
    it "contains keys that suggest 'super' was invoked for full config_rb setup" do
      cfg = subject.default_config_rb
      expect(cfg[:node_path]).to eq File.join(kitchen_root, "nodes")
    end

    it "adds the expected correct config for captured nodes" do
      cfg = subject.default_config_rb
      expect(cfg[:policies_path]).to eq File.join(kitchen_root, "policies")
      expect(cfg[:cookbook_artifacts_path]).to eq File.join(kitchen_root, "cookbook_artifacts")
      expect(cfg[:policy_groups_path]).to eq File.join(kitchen_root, "policy_groups")
    end
  end
end
