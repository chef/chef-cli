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

require "chef/formatters/doc"

module ChefCLI

  # Subclass of Chef's standard 'doc' formatter that mutes messages that occur
  # prior to convergence. This gives us cleaner output in general, but is
  # especially noticeable when the standard formatter is disabled by the
  # generator cookbook.
  class QuieterDocFormatter < Chef::Formatters::Doc

    cli_name(:chefcli_doc)

    # Called when starting to collect gems from the cookbooks
    def cookbook_gem_start(gems); end

    # Called when cookbook loading starts.
    def library_load_start(file_count); end

    # Called when cookbook loading starts.
    def profiles_load_start; end

    # Called when cookbook loading starts.
    def inputs_load_start; end

    # Called when cookbook loading starts.
    def waivers_load_start; end
  end
end
