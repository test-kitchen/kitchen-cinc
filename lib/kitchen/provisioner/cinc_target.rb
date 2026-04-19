#
# Copyright (C) 2023, Thomas Heinen
# Copyright (C) 2025, Cinc Project
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
      MIN_VERSION_REQUIRED = "19.0.0".freeze
      class CincVersionTooLow < UserError; end
      class CincClientNotFound < UserError; end
      class RequireTrainTransport < UserError; end

      default_config :install_strategy, "none"
      default_config :sudo, true

      def install_command; ""; end
      def init_command; ""; end
      def prepare_command; ""; end

      def chef_args(client_rb_filename)
        # Dummy execution to initialize and test remote connection
        connection = instance.remote_exec("echo Connection established")

        check_transport(connection)
        check_local_cinc_client

        instance_name = instance.name
        credentials_file = File.join(kitchen_basepath, ".kitchen", instance_name + ".ini")
        File.write(credentials_file, connection.credentials_file)

        super.push(
          "--target #{instance_name}",
          "--credentials #{credentials_file}"
        )
      end

      def check_transport(connection)
        debug("Checking for active transport")

        unless connection.respond_to? "train_uri"
          error("Cinc Target Mode provisioner requires a Train-based transport like kitchen-transport-train")
          raise RequireTrainTransport.new("No Train transport")
        end

        debug("Kitchen transport responds to train_uri function call, as required")
      end

      def check_local_cinc_client
        debug("Checking for cinc-client version")

        begin
          client_version = `cinc-client -v`.chop.split(":")[-1]
        rescue Errno::ENOENT => e
          error("Error determining Cinc Client version: #{e.exception.message}")
          raise CincClientNotFound.new("Need cinc-client installed locally")
        end

        minimum_version = Gem::Version.new(MIN_VERSION_REQUIRED)
        installed_version = Gem::Version.new(client_version)

        if installed_version < minimum_version
          error("Found Cinc Client version #{installed_version}, but require #{minimum_version} for Target Mode")
          raise CincVersionTooLow.new("Need version #{MIN_VERSION_REQUIRED} or higher")
        end

        debug("Cinc Client found and version constraints match")
      end

      def kitchen_basepath
        instance.driver.config[:kitchen_root]
      end

      def create_sandbox
        super

        # Change config.rb to point to the local sandbox path, not to /tmp/kitchen
        config[:root_path] = sandbox_path
        prepare_config_rb
      end

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
        Open3.popen2e(run_command) do |_stdin, output, _thread|
          output.each { |line| logger << line }
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
