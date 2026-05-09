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

# Loaded by kitchen-omnibus-chef's factory pattern when it detects
# kitchen-cinc is installed. See:
#   https://github.com/test-kitchen/kitchen-omnibus-chef/blob/main/lib/kitchen/provisioner/chef_infra.rb
#
# Drops the omnibus-chef ChefInfra binding (if present) so we can rebind to
# our subclass of CincInfra. The require_relative below resolves to our
# absolute file path, which is a different $LOADED_FEATURES entry from
# omnibus-chef's same-logical-named file — so it actually loads even when
# `require "kitchen/provisioner/chef_infra"` would short-circuit.
require "kitchen/provisioner/cinc_infra"

if Kitchen::Provisioner.const_defined?(:ChefInfra, false) &&
    !(Kitchen::Provisioner::ChefInfra <= Kitchen::Provisioner::CincInfra)
  Kitchen::Provisioner.send(:remove_const, :ChefInfra)
end

require_relative "../../kitchen/provisioner/chef_infra"
