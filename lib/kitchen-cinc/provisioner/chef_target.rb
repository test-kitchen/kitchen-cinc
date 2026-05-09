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

# See chef_infra.rb in this directory for the full rationale.
require "kitchen/provisioner/cinc_target"

if Kitchen::Provisioner.const_defined?(:ChefTarget, false) &&
    !(Kitchen::Provisioner::ChefTarget <= Kitchen::Provisioner::CincTarget)
  Kitchen::Provisioner.send(:remove_const, :ChefTarget)
end

require_relative "../../kitchen/provisioner/chef_target"
