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

require "kitchen/util"

module Kitchen
  module Provisioner
    # Helpers for the chef_* alias provisioners shipped by kitchen-cinc.
    #
    # The chef_* names have a priority order across kitchen-* gems:
    # kitchen-chef-enterprise > kitchen-cinc > kitchen-omnibus-chef. When a
    # higher-priority gem is installed, our chef_* alias should yield to it
    # rather than claim the constant. Users who explicitly want kitchen-cinc
    # behavior should use the cinc_* names in kitchen.yml.
    module ChefAliasLoader
      module_function

      # If kitchen-chef-enterprise is installed, attempt to load its
      # implementation of the named provisioner from its absolute path
      # (bypasses $LOAD_PATH ambiguity). Returns true if enterprise's
      # version was loaded and now owns the constant; false otherwise,
      # in which case the caller should register its own subclass.
      #
      # @param const_name [Symbol] the unqualified constant under
      #   Kitchen::Provisioner (e.g. :ChefInfra)
      # @return [Boolean]
      def defer_to_enterprise(const_name)
        spec = enterprise_spec
        return false unless spec

        file_name = Kitchen::Util.snake_case(const_name.to_s)
        path = File.join(spec.gem_dir, "lib", "kitchen", "provisioner", "#{file_name}.rb")
        return false unless File.exist?(path)

        require path
        Kitchen::Provisioner.const_defined?(const_name, false)
      end

      def enterprise_spec
        Gem::Specification.find_by_name("kitchen-chef-enterprise")
      rescue Gem::LoadError
        nil
      end
    end
  end
end
