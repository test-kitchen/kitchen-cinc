#
# Copyright (C) 2013, Fletcher Nichol
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

require "shellwords" unless defined?(Shellwords)
require "rbconfig" unless defined?(RbConfig)

require "kitchen/errors"
require "kitchen/logging"
require "kitchen/shell_out"
require "kitchen/which"

module Kitchen
  module Provisioner
    module Cinc
      # Cinc cookbook resolver that uses Policyfiles to calculate dependencies.
      #
      # @author Cinc Project
      class Policyfile
        include Logging
        include ShellOut
        include Which

        # Creates a new cookbook resolver.
        #
        # @param policyfile [String] path to a Policyfile
        # @param path [String] path in which to vendor the resulting
        #   cookbooks
        # @param logger [Kitchen::Logger] a logger to use for output, defaults
        #   to `Kitchen.logger`
        # @param always_update [Boolean] when true, run `<cli> update` after
        #   `<cli> install` so the policy lock is refreshed
        # @param policy_group [String, nil] policy group to export; nil exports
        #   without a `--policy_group` flag
        def initialize(policyfile, path, logger: Kitchen.logger, always_update: false, policy_group: nil)
          @policyfile    = policyfile
          @path          = path
          @logger        = logger
          @always_update = always_update
          @policy_group  = policy_group
        end

        # Loads the library code required to use the resolver.
        #
        # Policyfile resolution shells out to the Cinc Workstation CLI instead
        # of loading a Ruby library, so there is nothing to load and this is a
        # no-op. It exists so that both resolvers answer the same interface as
        # {Berkshelf.load!}.
        #
        # @param logger [Kitchen::Logger] a logger to use for output, defaults
        #   to `Kitchen.logger`
        # @return [void]
        def self.load!(logger: Kitchen.logger)
          # intentionally left blank
        end

        # Performs the cookbook resolution and vendors the resulting cookbooks
        # in the desired path, by running `<cli> export`.
        #
        # @return [void]
        # @raise [Kitchen::UserError] if no Workstation CLI can be found
        # @raise [Kitchen::ShellOut::ShellCommandFailed] if the export fails
        def resolve
          if policy_group
            info("Exporting cookbook dependencies from Policyfile #{path} with policy_group #{policy_group} using `#{cli_path} export`...")
            run_command("#{cli_path} export #{escape_path(policyfile)} #{escape_path(path)} --policy_group #{policy_group} --force")
          else
            info("Exporting cookbook dependencies from Policyfile #{path} using `#{cli_path} export`...")
            run_command("#{cli_path} export #{escape_path(policyfile)} #{escape_path(path)} --force")
          end
        end

        # Runs `<cli> install` to determine the correct cookbook set and
        # generate the policyfile lock, followed by `<cli> update` when
        # +always_update+ is set.
        #
        # @return [void]
        # @raise [Kitchen::UserError] if no Workstation CLI can be found
        # @raise [Kitchen::ShellOut::ShellCommandFailed] if a command fails
        def compile
          if File.exist?(lockfile)
            info("Installing cookbooks for Policyfile #{policyfile} using `#{cli_path} install`")
          else
            info("Policy lock file doesn't exist, running `#{cli_path} install` for Policyfile #{policyfile}...")
          end
          run_command("#{cli_path} install #{escape_path(policyfile)}")

          if always_update
            info("Updating policy lock using `#{cli_path} update`")
            run_command("#{cli_path} update #{escape_path(policyfile)}")
          end
        end

        # Return the path to the lockfile corresponding to this policyfile.
        #
        # @return [String] the Policyfile path with its `.rb` suffix replaced
        #   by `.lock.json`
        def lockfile
          policyfile.gsub(/\.rb\Z/, ".lock.json")
        end

        private

        # @return [String] path to a Policyfile
        # @api private
        attr_reader :policyfile

        # @return [String] path in which to vendor the resulting cookbooks
        # @api private
        attr_reader :path

        # @return [Kitchen::Logger] a logger to use for output
        # @api private
        attr_reader :logger

        # @return [Boolean] If true, always update cookbooks in the policy.
        # @api private
        attr_reader :always_update

        # @return [String] name of the policy_group, nil results in "local"
        # @api private
        attr_reader :policy_group

        # Escape spaces in a path in way that works with both Sh (Unix) and
        # Windows.
        #
        # @param path [String] Path to escape
        # @return [String] the quoted or backslash-escaped path
        # @api private
        def escape_path(path)
          if /mswin|mingw/.match?(RbConfig::CONFIG["host_os"])
            if /[ \t\n\v"]/.match?(path)
              "\"#{path.gsub(/[ \t\n\v\"\\]/) { |m| "\\" + m[0] }}\""
            else
              path
            end
          else
            Shellwords.escape(path)
          end
        end

        # Find a Workstation CLI in the path. `cinc-cli` and `cinc` are tried
        # first, then `chef-cli` and `chef` so an existing Chef Workstation
        # install still works. `cinc-cli` is the Ruby CLI shipped in the
        # `cinc-cli` gem.
        #
        # @api private
        # @return [String] absolute path to the first CLI found
        # @raise [Kitchen::UserError] if none of them are in the PATH
        def cli_path
          @cli_path ||= which("cinc-cli") || which("cinc") || which("chef-cli") || which("chef") || no_cli_found_error
        end

        # Logs an explanation of the missing Workstation CLI and aborts.
        #
        # @api private
        # @return [void] this method never returns normally
        # @raise [Kitchen::UserError] always
        def no_cli_found_error
          @logger.fatal("The `cinc`, `cinc-cli`, `chef`, or `chef-cli` executables cannot be found in your " \
                        "PATH. Ensure you have installed Cinc Workstation " \
                        "from https://cinc.sh/download/ and that your PATH " \
                        "setting includes the path to the `cinc` or `cinc-cli` commands.")
          raise UserError, "Could not find the cinc or cinc-cli executables in your PATH."
        end
      end
    end
  end
end
