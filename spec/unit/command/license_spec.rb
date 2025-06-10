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

# require "spec_helper"
# require "chef-cli/command/license"
# require "shared/command_with_ui_object"
# require "chef-cli/licensing/base"

# describe ChefCLI::Command::License do
#   it_behaves_like "a command with a UI object"

#   let(:params) { [] }
#   let(:ui) { TestHelpers::TestUI.new }

#   before do
#     # Disable the access of local licenses
#     allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_license_key_from_arg).and_return([])
#     allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_license_key_from_env).and_return([])
#     allow_any_instance_of(ChefLicensing::LicensingService::Local).to receive(:detected?).and_return(false)
#   end

#   let(:command) do
#     c = described_class.new
#     c.validate_params!(params)
#     c.ui = ui
#     c
#   end

#   it "disables debug by default" do
#     expect(command.debug?).to be(false)
#   end

#   context "invalid parameters passed" do
#     let(:multiple_params) { %w{add list} }
#     let(:invalid_command) { %w{not_a_subcommand} }

#     it "should fail with errors when multiple subcommands passed" do
#       expect(command.run(multiple_params)).to eq(1)
#     end

#     it "should fail for invalid argument" do
#       expect(command.run(invalid_command)).to eq(1)
#     end
#   end

#   context "license command" do
#     context "when pre-accepted license exists" do
#       let(:license_keys) { %w{tsmc-abcd} }

#       before(:each) do
#         allow(ChefLicensing).to receive(:fetch_and_persist).and_return(license_keys)
#       end

#       it "should be successful" do
#         expect { command.run(params) }.not_to raise_exception
#       end

#       it "should return the correct license key" do
#         expect(command.run(params)).to eq(license_keys)
#       end
#     end

#     context "when no licenses are accepted previously" do
#       let(:new_key) { ["tsmc-123456789"] }
#       before(:each) do
#         ChefLicensing.configure do |config|
#           config.license_server_url = "https://license.test"
#           config.chef_product_name = "chef"
#           config.chef_entitlement_id = "chef-entitled-id"
#           config.chef_executable_name = "chef"
#         end

#         # Disable the active license check
#         allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:licenses_active?).and_return(false)
#         # Disable the UI engine
#         allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:append_extra_info_to_tui_engine)
#         # Disable the API call to fetch the license type
#         allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:get_license_type).and_return("free")
#         # Disable the overwriting to the license.yml file
#         allow_any_instance_of(ChefLicensing::LicenseKeyFetcher::File).to receive(:persist)

#         # Mocks the user prompt to enter the license
#         allow_any_instance_of(ChefLicensing::LicenseKeyFetcher::Prompt).to receive(:fetch).and_return(new_key)
#         allow(ChefLicensing).to receive(:fetch_and_persist).and_return(new_key)
#       end

#       it "should create and stores the new license" do
#         expect { command.run(params) }.not_to raise_exception
#       end

#       it "should be same as the user entered license" do
#         expect(command.run(params)).to include(new_key.first)
#       end
#     end
#   end

#   context "chef license list command" do
#     let(:params) { %w{list} }
#     let(:license_key) { "tsmn-123123" }

#     before do
#       command.ui = ui
#     end

#     context "when no licenses are accepted" do
#       before do
#         allow_any_instance_of(ChefLicensing::ListLicenseKeys).to receive(:fetch_license_keys).and_return([])
#         allow_any_instance_of(ChefLicensing::ListLicenseKeys).to receive(:fetch_licenses_metadata).and_return([])
#       end

#       it "should return the correct error message" do
#         expect(command.run(params)).to eq([])
#       end
#     end

#     context "when there is a valid license" do
#       before do
#         allow(ChefLicensing).to receive(:list_license_keys_info).and_return(license_key)
#       end

#       it "should print the license details" do
#         expect(command.run(params)).to eq(license_key)
#       end
#     end
#   end

#   context "chef license add command" do
#     let(:params) { %w{add} }
#     let(:license_key) { ["tsmn-123123"] }

#     before do
#       # Disable the API call to fetch the license type
#       allow_any_instance_of(ChefLicensing::LicenseKeyFetcher).to receive(:get_license_type).and_return("free")
#       # Disable the overwriting to the license.yml file
#       allow_any_instance_of(ChefLicensing::LicenseKeyFetcher::File).to receive(:persist)
#       # Mocks the user prompt to enter the license
#       allow_any_instance_of(ChefLicensing::LicenseKeyFetcher::Prompt).to receive(:fetch).and_return(license_key)
#     end

#     it "should not raise any errors" do
#       expect { command.run(params) }.not_to raise_exception
#     end

#     it "should create and store the new license" do
#       expect(command.run(params)).to include(license_key.first)
#     end
#   end
# end
