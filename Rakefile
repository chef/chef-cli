#
#  Copyright (c) 2019-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    require "rubocop/rake_task"

    desc "Run Cookbook Ruby style checks"
    RuboCop::RakeTask.new(:cookstyle) do |t|
      t.requires = ["cookstyle"]
      t.patterns = ["lib/chef-cli/skeletons/code_generator"]
      t.options = ["--display-cop-names"]
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end

  desc "Run Chef Ruby style checks"
  task :chefstyle do
    require "rubocop/rake_task"
    require "cookstyle/chefstyle"

    if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
      # Windows-specific command, rubocop erroneously reports the CRLF in each file which is removed when your PR is uploaded to GitHub.
      # This is a workaround to ignore the CRLF from the files before running cookstyle.
      sh "cookstyle --chefstyle -c .rubocop.yml --except Layout/EndOfLine --display-cop-names"
    else
      sh "cookstyle --chefstyle -c .rubocop.yml --display-cop-names"
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end
end

