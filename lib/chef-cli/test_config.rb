#
# Copyright:: Copyright (c) 2019 Chef Software Inc.
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

require "tomlrb"
require "net/http"

module ChefCLI
  class TestConfig

    def initialize(path = nil)
      @config_path = path
      @config_hash = load_config_file(@config_path)
      @version = @config_hash.nil? ? nil : 0 # 0 means the delivery project.toml
    end

    attr_accessor :config_hash
    attr_accessor :version

    def validate!
      raise "No config content found in #{@config_path}!" if @config_hash.nil?
      raise "No phases defined in the #{@config_path}. Make sure it contains a [local_phases] section." unless @config_hash["local_phases"]
    end

    private

    def load_config_file(config_path)
      raise "No test config found at #{@config_path}" unless File.exist?(@config_path)

      config = load_toml_file(config_path)

       # if there's a remote_file config option then return that content. Otherwise use what we have
      if config.key?("remote_file")
        parse_toml(fetch_remote_content(config["remote_file"]))
      else
        return config
      end
    end

    def load_toml_file(path)
      Tomlrb.load_file(path)
    rescue => e
      message = "Unable to parse the Delivery Local Mode config file: #{path}\n"
      message << e.message
      raise message
    end

    def parse_toml(content)
      Tomlrb.parse(content)
    rescue => e
      message = "Unable to parse the Delivery Local Mode config's remote_file content\n"
      message << e.message
      raise message
    end

    def fetch_remote_content(uri)
      Net::HTTP.get(URI(uri))
    rescue Errno::ECONNREFUSED
      raise "Could not connect to the host to fetch the remote configuration file at #{uri}"
    end
  end
end
