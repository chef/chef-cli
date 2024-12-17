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

require "json" unless defined?(JSON)
require_relative "../cookbook_omnifetch"
require_relative "source_uri"
require_relative "../exceptions"
require "chef/http/simple" unless defined?(Chef::HTTP::Simple)

module ChefCLI
  module Policyfile
    class ArtifactoryCookbookSource

      attr_reader :uri
      attr_reader :preferred_cookbooks
      attr_reader :chef_config

      def initialize(uri, chef_config: nil)
        @uri = uri
        @http_connections = {}
        @chef_config = chef_config
        @preferred_cookbooks = []
        yield self if block_given?
      end

      def default_source_args
        [:artifactory, uri]
      end

      def ==(other)
        other.is_a?(self.class) && other.uri == uri && other.preferred_cookbooks == preferred_cookbooks
      end

      def preferred_for(*cookbook_names)
        preferred_cookbooks.concat(cookbook_names)
      end

      def preferred_source_for?(cookbook_name)
        preferred_cookbooks.include?(cookbook_name)
      end

      def universe_graph
        @universe_graph ||= full_community_graph.inject({}) do |normalized_graph, (cookbook_name, metadata_by_version)|
          normalized_graph[cookbook_name] = metadata_by_version.inject({}) do |deps_by_version, (version, metadata)|
            deps_by_version[version] = metadata["dependencies"]
            deps_by_version
          end
          normalized_graph
        end
      end

      def source_options_for(cookbook_name, cookbook_version)
        base_uri = full_community_graph[cookbook_name][cookbook_version]["download_url"]
        {
          artifactory: base_uri,
          version: cookbook_version,
          http_client: http_connection_for(base_uri.to_s),
        }
      end

      def null?
        false
      end

      def desc
        "artifactory(#{uri})"
      end

      def artifactory_api_key
        chef_config&.artifactory_api_key || (ENV["ARTIFACTORY_API_KEY"] unless ENV["ARTIFACTORY_API_KEY"].to_s.strip.empty?)
      end

      def artifactory_identity_token
        chef_config&.artifactory_identity_token || (ENV["ARTIFACTORY_IDENTITY_TOKEN"] unless ENV["ARTIFACTORY_IDENTITY_TOKEN"].to_s.strip.empty?)
      end

      private

      def auth_headers
        if artifactory_identity_token
          { "Authorization" => "Bearer #{artifactory_identity_token}" }
        else
          { "X-Jfrog-Art-API" => artifactory_api_key }
        end
      end

      def http_connection_for(base_url)
        @http_connections[base_url] ||= Chef::HTTP::Simple.new(base_url, headers: auth_headers)
      end

      def full_community_graph
        @full_community_graph ||=
          begin
            graph_json = http_connection_for(uri).get("/universe")
            JSON.parse(graph_json)
          end
      end

    end
  end
end
