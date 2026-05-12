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

# Priority order for chef_* names: kitchen-chef-enterprise > kitchen-cinc >
# kitchen-omnibus-chef. If enterprise is installed, defer to it. Users who
# explicitly want kitchen-cinc should use cinc_infra in kitchen.yml.
unless Kitchen::Provisioner::ChefAliasLoader.defer_to_enterprise(:ChefInfra)
  # If kitchen-omnibus-chef has already defined Kitchen::Provisioner::ChefInfra
  # with a non-CincInfra parent (i.e. omnibus-chef's gem loaded first), drop
  # the binding before we redefine — otherwise Ruby raises TypeError on
  # superclass mismatch. The two gems coordinate via this swap; see the
  # kitchen-omnibus-chef factory in chef_infra.rb#new for the other side.
  if Kitchen::Provisioner.const_defined?(:ChefInfra, false) &&
      !(Kitchen::Provisioner::ChefInfra <= Kitchen::Provisioner::CincInfra)
    Kitchen::Provisioner.send(:remove_const, :ChefInfra)
  end

  module Kitchen
    module Provisioner
      # Alias for CincInfra. Lets existing kitchen.yml files using
      # `provisioner: name: chef_infra` transparently use Cinc Client.
      class ChefInfra < CincInfra
        kitchen_provisioner_api_version 2

        plugin_version Kitchen::VERSION
      end
    end
  end
end
