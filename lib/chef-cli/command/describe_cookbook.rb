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

require_relative "base"
require_relative "../ui"
require_relative "../cookbook_profiler/identifiers"
require_relative "../dist"

module ChefCLI
  class IdDumper

    attr_reader :cb_path
    attr_reader :ui

    def initialize(ui, cb_relpath)
      @ui = ui
      @cb_path = cb_relpath
    end

    def run
      id = ChefCLI::CookbookProfiler::Identifiers.new(cookbook_version)
      ui.msg "Path: #{cookbook_path}"
      ui.msg "SemVer version: #{id.semver_version}"
      ui.msg "Identifier: #{id.content_identifier}"
      ui.msg "File fingerprints:"
      ui.msg id.fingerprint_text
    end

    def cookbook_version
      @cookbook_version ||= cookbook_loader.cookbook_version
    end

    def cookbook_path
      File.expand_path(cb_path)
    end

    def cookbook_loader
      @cookbook_loader ||=
        begin
          loader = Chef::Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore)
          loader.load!
          loader
        end
    end

    def chefignore
      @chefignore ||= Chef::Cookbook::Chefignore.new(File.join(cookbook_path, "chefignore"))
    end
  end

  module Command

    class DescribeCookbook < ChefCLI::Command::Base

      banner "Usage: #{ChefCLI::Dist::EXEC} describe-cookbook <path/to/cookbook>"

      attr_reader :cookbook_path
      attr_reader :ui

      def initialize(*args)
        super
        @cookbook_path = nil
        @ui = UI.new
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        return 1 unless check_cookbook_path

        IdDumper.new(ui, cookbook_path).run
      end

      def check_cookbook_path
        unless File.exist?(cookbook_path)
          ui.err("Given cookbook path '#{cookbook_path}' does not exist or is not readable")
          return false
        end

        mdrb_path = File.join(cookbook_path, "metadata.rb")
        mdjson_path = File.join(cookbook_path, "metadata.json")

        unless File.exist?(mdrb_path) || File.exist?(mdjson_path)
          ui.err("Given cookbook path '#{cookbook_path}' does not appear to be a cookbook, it does not contain a metadata.rb or metadata.json")
          return false
        end
        true
      end

      def apply_params!(params)
        remaining_args = parse_options(params)
        if remaining_args.size != 1
          ui.err(opt_parser)
          false
        else
          @cookbook_path = File.expand_path(remaining_args.first)
          true
        end
      end

    end
  end
end
