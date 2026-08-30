#
# Copyright (C) 2023, Thomas Heinen
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

module Kitchen
  module Provisioner
    # Cinc Target Mode provisioner for remote execution.
    #
    # Requires Cinc Client 19.0.0+ and Train-based transport.
    #
    # @author Cinc Project
    class CincTarget < CincInfra
      # Oldest Cinc Client that supports Target Mode.
      MIN_VERSION_REQUIRED = "19.0.0".freeze

      # Raised when the local Cinc Client predates Target Mode support.
      class CincVersionTooLow < UserError; end

      # Raised when no cinc-client executable can be found locally.
      class CincClientNotFound < UserError; end

      # Raised when the configured transport is not Train-based.
      class RequireTrainTransport < UserError; end

      default_config :install_strategy, "none"
      default_config :sudo, true

      # @return [String] empty; Target Mode runs the client locally, so there
      #   is nothing to install on the instance
      def install_command; ""; end
      # @return [String] empty; nothing is staged on the instance
      def init_command; ""; end
      # @return [String] empty; nothing is prepared on the instance
      def prepare_command; ""; end

      # Builds the cinc-client arguments, adding the Target Mode flags.
      #
      # Writes the transport's credentials to a per-instance file under
      # .kitchen/ and points --credentials at it, because Target Mode drives the
      # instance over Train from the workstation rather than running on it.
      #
      # @param client_rb_filename [String] the generated client.rb
      # @return [Array<String>] command line arguments
      # @raise [RequireTrainTransport] if the transport is not Train-based
      # @raise [CincClientNotFound] if cinc-client is not installed locally
      # @raise [CincVersionTooLow] if the local cinc-client is too old
      def chef_args(client_rb_filename)
        # Dummy execution to initialize and test remote connection
        connection = instance.remote_exec("echo Connection established")

        check_transport(connection)
        check_local_cinc_client

        instance_name = instance.name
        credentials_file = File.join(kitchen_basepath, ".kitchen", instance_name + ".ini")
        FileUtils.mkdir_p(File.dirname(credentials_file))
        File.write(credentials_file, connection.credentials_file)
        # The credentials file holds the transport's secrets (keys, passwords),
        # so keep it readable only by the user running kitchen.
        File.chmod(0600, credentials_file)

        super.push(
          %{--target "#{instance_name}"},
          %{--credentials "#{credentials_file}"}
        )
      end

      # Verifies the configured transport can hand over a Train URI.
      #
      # @param connection [Object] the transport connection
      # @return [void]
      # @raise [RequireTrainTransport] if it cannot
      def check_transport(connection)
        debug("Checking for active transport")

        unless connection.respond_to? "train_uri"
          error("Cinc Target Mode provisioner requires a Train-based transport like kitchen-transport-train")
          raise RequireTrainTransport.new("No Train transport")
        end

        debug("Kitchen transport responds to train_uri function call, as required")
      end

      # Verifies a new enough cinc-client is installed on the workstation.
      #
      # @return [void]
      # @raise [CincClientNotFound] if the executable is missing, or if its
      #   version cannot be determined
      # @raise [CincVersionTooLow] if it is older than {MIN_VERSION_REQUIRED}
      def check_local_cinc_client
        debug("Checking for cinc-client version")

        begin
          version_output = `cinc-client -v`
        rescue Errno::ENOENT => e
          error("Error determining Cinc Client version: #{e.exception.message}")
          raise CincClientNotFound.new("Need cinc-client installed locally")
        end

        # `cinc-client -v` prints something like "Cinc Client: 19.1.31". Pull the
        # version out by pattern rather than by splitting on ":", so unexpected
        # output produces a readable error instead of a malformed-version crash.
        client_version = version_output.to_s[/\d+(?:\.\d+)+/]
        if client_version.nil?
          error("Could not parse a Cinc Client version from `cinc-client -v` " \
                "output: #{version_output.to_s.strip.inspect}")
          raise CincClientNotFound.new("Could not determine the local cinc-client version")
        end

        minimum_version = Gem::Version.new(MIN_VERSION_REQUIRED)
        installed_version = Gem::Version.new(client_version)

        if installed_version < minimum_version
          error("Found Cinc Client version #{installed_version}, but require #{minimum_version} for Target Mode")
          raise CincVersionTooLow.new("Need version #{MIN_VERSION_REQUIRED} or higher")
        end

        debug("Cinc Client found and version constraints match")
      end

      # @return [String] the kitchen root, from the driver's configuration
      def kitchen_basepath
        instance.driver.config[:kitchen_root]
      end

      # Builds the sandbox and repoints the config at it.
      #
      # Target Mode reads config.rb from the local sandbox rather than from
      # /tmp/kitchen on the instance, so root_path is rewritten before the
      # config is generated.
      #
      # @return [void]
      def create_sandbox
        super

        # Change config.rb to point to the local sandbox path, not to /tmp/kitchen
        config[:root_path] = sandbox_path
        prepare_config_rb
      end

      # Runs the whole converge from the workstation.
      #
      # Uploads, runs cinc-client locally against the remote target while
      # streaming its output into the Test Kitchen logger, then downloads. The
      # sandbox is cleaned up whether or not the run succeeded.
      #
      # @param state [Hash] instance state describing how to connect
      # @return [void]
      # @raise [Kitchen::ActionFailed] if the transport fails, or if
      #   cinc-client exits non-zero
      def call(state)
        remote_connection = instance.transport.connection(state)

        config[:uploads].to_h.each do |locals, remote|
          debug("Uploading #{Array(locals).join(", ")} to #{remote}")
          remote_connection.upload(locals.to_s, remote)
        end

        # no installation
        create_sandbox
        # no prepare command

        # Stream output to logger
        require "open3"
        status = Open3.popen2e(run_command) do |_stdin, output, thread|
          output.each { |line| logger << line }
          thread.value
        end

        unless status.success?
          raise ActionFailed,
            "Cinc Client exited with code #{status.exitstatus} on #{instance.to_str}"
        end

        info("Downloading files from #{instance.to_str}")
        config[:downloads].to_h.each do |remotes, local|
          debug("Downloading #{Array(remotes).join(", ")} to #{local}")
          remote_connection.download(remotes, local)
        end
        debug("Download complete")
      rescue Kitchen::Transport::TransportFailed => ex
        raise ActionFailed, ex.message
      ensure
        cleanup_sandbox
      end
    end
  end
end
