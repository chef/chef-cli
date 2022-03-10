
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
require "chef-cli/cookbook_omnifetch"

describe "CookbookOmnifetch dependency" do
  describe "lambda for default_chef_server_http_client" do
    context "after chef config is loaded" do
      let(:url) { "https://chef.example/organizations/myorg" }
      let(:key_path) { "/path/to/my/key.pem" }
      let(:username) { "my-username" }

      before do
        Chef::Config.chef_server_url(url)
        Chef::Config.client_key(key_path)
        Chef::Config.node_name(username)
      end

      it "creates a default chef server HTTP client for Omnifetch" do
        client = CookbookOmnifetch.default_chef_server_http_client
        expect(client).to be_a_kind_of(ChefCLI::ChefServerAPIMulti)
        expect(client.url).to eq(url)
        expect(client.opts[:signing_key_filename]).to eq(key_path)
        expect(client.opts[:client_name]).to eq(username)
      end
    end

    context "before chef config is loaded" do
      it "raises an exception" do
        expect { CookbookOmnifetch.default_chef_server_http_client }
          .to raise_exception(ChefCLI::BUG)
      end
    end
  end
end
