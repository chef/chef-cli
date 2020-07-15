#
# Author:: Marc Paradise <marc@chef.io>
#
# Copyright (C) 2020, Chef Software Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "json"
require "kitchen"
require "kitchen/provisioner/base"
require "kitchen/provisioner/chef_zero"

module Kitchen
  module Provisioner
    # For use in a provisioner that does not do any run list evaluation or
    # policy/berks file expansion.
    class ChefZeroCaptureSandbox < Chef::CommonSandbox
      def populate
        super
        prepare(:policies)
        prepare(:policy_groups)
        prepare(:cookbook_artifacts)
      end

      # Override #prepare_cookbooks because we don't want any cookbook resolving to occur
      # via kitchen through berks, policy
      def prepare_cookbooks
        cp_cookbooks
        filter_only_cookbook_files
      end
    end

    # chef-zero provisioner intended for use with `chef capture`.
    #
    # This provisioner does not do any cookbook dependency
    # resolution and will not pull in external cookbooks.  All cookbooks
    # or cookbook artificats  + policy data as captured from the live node and are
    # expected to be available for chef-zero to provide to the client.
    class ChefZeroCapture < ChefZero
      # Declaring these ensure that they're available to the sandbox - it's initialized
      # the provider's configoptions.
      default_config :policies_path, "policies"
      default_config :policy_groups_path, "policy_groups"
      default_config :cookbook_artifacts_path, "cookbook_artifacts"

      # This will load policyfile/berkshelf.  We don't want either - the client resolves all
      # dependencies from chef-zero, exactly as preppped in the captured repository.
      def load_needed_dependencies!; end

      def create_sandbox
        # We have to invoke the the true Base create_sandbox because it does setup that
        # we want. However, we do not want to invoke the create_sandbox inherited from
        # ChefZero/ChefBase - those will create and populate a ChefCommonSandbox instead
        # of a ChefZeroCaptureSandbox.
        m = Base.instance_method(:create_sandbox).bind(self)
        m.call

        # These behaviors from super we _do_ want, so we need to copy them here.
        prepare_validation_pem
        prepare_config_rb
        ChefZeroCaptureSandbox.new(config, sandbox_path, instance).populate
      end

      # Overriding the private ProviderChefZero#default_config_rb
      # so that we can add additional configuratoin required for  chef-zeor
      # to be able to locate our policies/, policy groups, and cookbook artifacts
      # at run-time.
      def default_config_rb
        cfg = super
        # Need to tell chef-zero about our additional config.
        root = config[:root_path].gsub("$env:TEMP", "\#{ENV['TEMP']\}")
        cfg[:policies_path] = remote_path_join(root, config[:policies_path])
        cfg[:policy_groups_path] = remote_path_join(root, config[:policy_groups_path])
        cfg[:cookbook_artifacts_path] = remote_path_join(root, config[:cookbook_artifacts_path])
        cfg
      end
    end
  end
end
