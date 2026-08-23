#
# Copyright (C) 2015, HiganWorks LLC
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

# Usage:
#
# puts your recipes to `apply/` directory.
#
# An example of .kitchen.yml.
#
# ---
# driver:
#   name: vagrant
#
# provisioner:
#   name: cinc_apply
#
# platforms:
#   - name: ubuntu-24.04
#   - name: almalinux-10
#
# suites:
#   - name: default
#     run_list:
#       - recipe1
#       - recipe2
#
#
# The cinc-apply runs twice below.
#
# cinc-apply apply/recipe1.rb
# cinc-apply apply/recipe2.rb

require_relative "cinc_base"

module Kitchen
  module Provisioner
    # Cinc Apply provisioner.
    #
    # @author Cinc Project
    class CincApply < CincBase
      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION

      default_config :cinc_apply_path do |provisioner|
        provisioner
          .remote_path_join(%W{#{provisioner[:cinc_omnibus_root]} bin cinc-apply})
          .tap { |path| path.concat(".bat") if provisioner.windows_os? }
      end

      default_config :ruby_bindir do |provisioner|
        provisioner
          .remote_path_join(%W{#{provisioner[:cinc_omnibus_root]} embedded bin})
      end

      default_config :apply_path do |provisioner|
        provisioner.calculate_path("apply")
      end
      expand_path_for :apply_path

      # Builds a sandbox containing just the recipes to apply.
      #
      # Unlike the other provisioners this does not stage cookbooks, data bags,
      # or roles -- cinc-apply runs single recipes, so only the node JSON and the
      # apply directory are needed.
      #
      # @return [void]
      def create_sandbox
        @sandbox_path = Dir.mktmpdir("#{instance.name}-sandbox-")
        File.chmod(0755, sandbox_path)
        info("Preparing files for transfer")
        debug("Creating local sandbox in #{sandbox_path}")

        prepare_json
        prepare(:apply)
      end

      # Shell code that prepares the apply directory on the instance.
      #
      # @return [String] platform-appropriate shell code
      def init_command
        dirs = %w{
          apply
        }.sort.map { |dir| remote_path_join(config[:root_path], dir) }

        vars = if powershell_shell?
                 init_command_vars_for_powershell(dirs)
               else
                 init_command_vars_for_bourne(dirs)
               end

        prefix_command(shell_code_from_file(vars, "cinc_base_init_command"))
      end

      # Shell code that runs cinc-apply once per recipe in the run list.
      #
      # @return [String] platform-appropriate shell code
      def run_command
        level = config[:log_level]
        lines = []
        config[:run_list].map do |recipe|
          cmd = sudo(config[:cinc_apply_path]).dup
            .tap { |str| str.insert(0, "& ") if powershell_shell? }
          args = [
            "apply/#{recipe}.rb",
            "--log_level #{level}",
            "--no-color",
          ]
          args << "--logfile #{config[:log_file]}" if config[:log_file]

          lines << wrap_shell_code(
            [cmd, *args].join(" ")
            .tap { |str| str.insert(0, reload_ps1_path) if windows_os? }
          )
        end

        prefix_command(lines.join("\n"))
      end
    end
  end
end
