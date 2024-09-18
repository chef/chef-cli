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
require_relative "config"

module ChefCLI
  module Licensing
    class Base
      class << self
        def validate
          ChefLicensing.fetch_and_persist.each do |license_key|
            puts "License Key: #{license_key}"
          end
        end

        def list
          ChefLicensing.list_license_keys_info
        end

        def add
          ChefLicensing.add_license
        end
      end
    end
  end
end
