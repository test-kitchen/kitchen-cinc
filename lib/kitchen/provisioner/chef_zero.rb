#
# Copyright (C) 2026, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "cinc_infra"
require_relative "chef_alias_loader"

# Deprecated alias for ChefInfra (which itself is an alias for CincInfra).
# Provided for backward compatibility with kitchen.yml files using the
# legacy chef_zero provisioner name.
#
# See chef_infra.rb for the priority and remove_const rationale.
unless Kitchen::Provisioner::ChefAliasLoader.defer_to_enterprise(:ChefZero)
  if Kitchen::Provisioner.const_defined?(:ChefZero, false) &&
      !(Kitchen::Provisioner::ChefZero <= Kitchen::Provisioner::CincInfra)
    Kitchen::Provisioner.send(:remove_const, :ChefZero)
  end

  module Kitchen
    module Provisioner
      # Deprecated alias for {CincInfra}, kept so existing kitchen.yml files
      # naming the +chef_zero+ provisioner keep working.
      #
      # Prefer +cinc_infra+ in new configuration.
      class ChefZero < CincInfra
        kitchen_provisioner_api_version 2

        plugin_version Kitchen::VERSION
      end
    end
  end
end
