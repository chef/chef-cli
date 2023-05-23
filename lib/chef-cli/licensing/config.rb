# frozen_string_literal: true

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

require "chef-licensing"

ChefLicensing.configure do |config|
  config.chef_product_name = "chef"
  config.chef_entitlement_id = "a5213d76-181f-4924-adba-4b7ed2b098b5"
  config.chef_executable_name = "chef"
end
