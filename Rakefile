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
#
require "bundler/gem_tasks"

namespace :style do
  begin
    desc "Run Cookbook Ruby style checks"
    task :cookstyle do
      sh "find lib/chef-cli/skeletons/code_generator -name '*.rb' -print0 | xargs -0 cookstyle --display-cop-names"
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end

  begin
    desc "Run Chef Ruby style checks"
    task :chefstyle do
      sh "cookstyle --chefstyle --display-cop-names"
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end
end
