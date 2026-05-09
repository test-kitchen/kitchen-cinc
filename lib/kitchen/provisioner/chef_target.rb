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

require_relative "cinc_target"

# See chef_infra.rb for the rationale on this remove_const guard.
if Kitchen::Provisioner.const_defined?(:ChefTarget, false) &&
    !(Kitchen::Provisioner::ChefTarget <= Kitchen::Provisioner::CincTarget)
  Kitchen::Provisioner.send(:remove_const, :ChefTarget)
end

module Kitchen
  module Provisioner
    # Alias for CincTarget. Lets existing kitchen.yml files using
    # `provisioner: name: chef_target` transparently use Cinc Target Mode.
    class ChefTarget < CincTarget
      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION
    end
  end
end
