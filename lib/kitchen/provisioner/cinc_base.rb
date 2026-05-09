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

require "fileutils" unless defined?(FileUtils)
require "pathname" unless defined?(Pathname)
require "json" unless defined?(JSON)
require "cgi" unless defined?(CGI)
require "kitchen/util"

require_relative "cinc/policyfile"
require_relative "cinc/berkshelf"
require_relative "cinc/common_sandbox"

begin
  require "chef-config/config"
  require "chef-config/workstation_config_loader"
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # This space left intentionally blank.
end

module Kitchen
  module Provisioner
    # Common implementation details for Cinc-related provisioners.
    #
    # @author Cinc Project
    class CincBase < Base
      default_config :run_list, []
      default_config :policy_group, nil
      default_config :attributes, {}
      default_config :config_path, nil
      default_config :log_file, nil
      default_config :log_level do |provisioner|
        provisioner[:debug] ? "debug" : "auto"
      end
      default_config :profile_ruby, false
      # The older policyfile_zero used `policyfile` so support it for compat.
      default_config :policyfile, nil
      # Will try to autodetect by searching for `Policyfile.rb` if not set.
      # If set, will error if the file doesn't exist.
      default_config :policyfile_path, nil
      # Will try to autodetect by searching for `Berksfile` if not set.
      # If set, will error if the file doesn't exist.
      default_config :berksfile_path, nil
      # If set to true (which is the default from `chef generate`), try to update
      # backend cookbook downloader on every kitchen run.
      default_config :always_update_cookbooks, true
      default_config :cookbook_files_glob, %w(
        README.* VERSION metadata.{json,rb} attributes.rb recipe.rb
        attributes/**/* definitions/**/* files/**/* libraries/**/*
        providers/**/* recipes/**/* resources/**/* templates/**/*
        ohai/**/* compliance/**/*
      ).join(",")
      # to ease upgrades, allow the user to turn deprecation warnings into errors
      default_config :deprecations_as_errors, false

      # Override the default from Base so reboot handling works by default for Cinc.
      default_config :retry_on_exit_code, [35, 213]

      default_config :multiple_converge, 1

      default_config :enforce_idempotency, false

      default_config :data_path do |provisioner|
        provisioner.calculate_path("data")
      end
      expand_path_for :data_path

      default_config :data_bags_path do |provisioner|
        provisioner.calculate_path("data_bags")
      end
      expand_path_for :data_bags_path

      default_config :environments_path do |provisioner|
        provisioner.calculate_path("environments")
      end
      expand_path_for :environments_path

      default_config :nodes_path do |provisioner|
        provisioner.calculate_path("nodes")
      end
      expand_path_for :nodes_path

      default_config :roles_path do |provisioner|
        provisioner.calculate_path("roles")
      end
      expand_path_for :roles_path

      default_config :clients_path do |provisioner|
        provisioner.calculate_path("clients")
      end
      expand_path_for :clients_path

      default_config :encrypted_data_bag_secret_key_path do |provisioner|
        provisioner.calculate_path("encrypted_data_bag_secret_key", type: :file)
      end
      expand_path_for :encrypted_data_bag_secret_key_path

      #
      # Modern configuration options (RFC 091 equivalent for Cinc)
      #

      # Default product_name to "cinc" so that the modern Mixlib::Install
      # code path is used automatically.
      default_config :product_name, "cinc"

      default_config :product_version, :latest

      default_config :channel, :stable

      default_config :install_strategy, "once"

      default_config :platform

      default_config :platform_version

      default_config :architecture

      default_config :download_url

      default_config :checksum

      # Mapping of deprecated chef_*-prefixed config keys to their cinc_*
      # equivalents. Lets existing kitchen.yml files using the chef_* names
      # keep working when migrating from kitchen-omnibus-chef to kitchen-cinc.
      CHEF_TO_CINC_KEYS = {
        require_chef_omnibus: :require_cinc_omnibus,
        chef_omnibus_url: :cinc_omnibus_url,
        chef_omnibus_install_options: :cinc_omnibus_install_options,
        chef_omnibus_root: :cinc_omnibus_root,
        chef_client_path: :cinc_client_path,
        chef_solo_path: :cinc_solo_path,
        chef_apply_path: :cinc_apply_path,
        chef_zero_host: :cinc_zero_host,
        chef_zero_port: :cinc_zero_port,
      }.freeze

      CHEF_TO_CINC_KEYS.each do |chef_key, cinc_key|
        deprecate_config_for chef_key,
          "The '#{chef_key}' attribute is deprecated; use '#{cinc_key}' instead."
      end

      # Reads the local Chef::Config object (if present). We do this because
      # we want to start bringing Cinc config and Cinc Workstation config closer
      # together. For example, we want to configure proxy settings in 1
      # location instead of 3 configuration files.
      #
      # @param config [Hash] initial provided configuration
      def initialize(config = {})
        # Forward any chef_*-prefixed keys to their cinc_* equivalents so that
        # the cinc_* default_config blocks see them as already-set and skip
        # their default values. The chef_* key is preserved so that
        # deprecate_config_for can emit a warning via `kitchen doctor`.
        CHEF_TO_CINC_KEYS.each do |chef_key, cinc_key|
          next unless config.key?(chef_key)
          next if config.key?(cinc_key)

          config[cinc_key] = config[chef_key]
        end

        super(config)

        if defined?(ChefConfig::WorkstationConfigLoader)
          ChefConfig::WorkstationConfigLoader.new(config[:config_path]).load
        end
        # This exports any proxy config present in the config to
        # appropriate environment variables, which Test Kitchen respects
        ChefConfig::Config.export_proxies if defined?(ChefConfig::Config.export_proxies)
      end

      # (see Base#create_sandbox)
      def create_sandbox
        super
        sanity_check_sandbox_options!
        Cinc::CommonSandbox.new(config, sandbox_path, instance).populate
      end

      # (see Base#init_command)
      def init_command
        dirs = %w{
          cookbooks data data_bags environments roles clients
          encrypted_data_bag_secret
        }.sort.map { |dir| remote_path_join(config[:root_path], dir) }

        vars = if powershell_shell?
                 init_command_vars_for_powershell(dirs)
               else
                 init_command_vars_for_bourne(dirs)
               end

        prefix_command(shell_code_from_file(vars, "cinc_base_init_command"))
      end

      # (see Base#install_command)
      def install_command
        return unless config[:product_name]
        return if config[:install_strategy] == "skip"

        prefix_command(install_script_contents)
      end

      private

      def last_exit_code
        "; exit $LastExitCode" if powershell_shell?
      end

      # @return [String] an absolute path to a Policyfile, relative to the
      #   kitchen root
      # @api private
      def policyfile
        policyfile_basename = config[:policyfile_path] || config[:policyfile] || "Policyfile.rb"
        File.expand_path(policyfile_basename, config[:kitchen_root])
      end

      # @return [String] an absolute path to a Berksfile, relative to the
      #   kitchen root
      # @api private
      def berksfile
        berksfile_basename = config[:berksfile_path] || config[:berksfile] || "Berksfile"
        File.expand_path(berksfile_basename, config[:kitchen_root])
      end

      # Generates a Hash with default values for a solo.rb or client.rb
      # configuration file.
      #
      # @return [Hash] a configuration hash
      # @api private
      def default_config_rb
        root = config[:root_path].gsub("$env:TEMP", "\#{ENV['TEMP']}")

        {
          node_name: instance.name,
          checksum_path: remote_path_join(root, "checksums"),
          file_cache_path: remote_path_join(root, "cache"),
          file_backup_path: remote_path_join(root, "backup"),
          cookbook_path: [
            remote_path_join(root, "cookbooks"),
            remote_path_join(root, "site-cookbooks"),
          ],
          data_bag_path: remote_path_join(root, "data_bags"),
          environment_path: remote_path_join(root, "environments"),
          node_path: remote_path_join(root, "nodes"),
          role_path: remote_path_join(root, "roles"),
          client_path: remote_path_join(root, "clients"),
          user_path: remote_path_join(root, "users"),
          validation_key: remote_path_join(root, "validation.pem"),
          client_key: remote_path_join(root, "client.pem"),
          chef_server_url: "http://127.0.0.1:8889",
          encrypted_data_bag_secret: remote_path_join(
            root, "encrypted_data_bag_secret"
          ),
          treat_deprecation_warnings_as_errors: config[:deprecations_as_errors],
        }
      end

      # Generates a rendered client.rb/solo.rb formatted file as a
      # String.
      #
      # @param data [Hash] a key/value pair hash of configuration
      # @return [String] a rendered config file as a String
      # @api private
      def format_config_file(data)
        data.each.map do |attr, value|
          [attr, format_value(value)].join(" ")
        end.join("\n")
      end

      # Converts a Ruby object to a String interpretation suitable for writing
      # out to a client.rb/solo.rb file.
      #
      # @param obj [Object] an object
      # @return [String] a string representation
      # @api private
      def format_value(obj)
        if obj.is_a?(String) && obj =~ /^:/
          obj
        elsif obj.is_a?(String)
          %{"#{obj.gsub(/["\\]/) { |m| "\\" + m }}"}
        elsif obj.is_a?(Array)
          %{[#{obj.map { |i| format_value(i) }.join(", ")}]}
        else
          obj.inspect
        end
      end

      # Generates the init command variables for Bourne shell-based platforms.
      #
      # @param dirs [Array<String>] directories
      # @return [String] shell variable lines
      # @api private
      def init_command_vars_for_bourne(dirs)
        [
          shell_var("sudo_rm", sudo("rm")),
          shell_var("dirs", dirs.join(" ")),
          shell_var("root_path", config[:root_path]),
        ].join("\n")
      end

      # Generates the init command variables for PowerShell-based platforms.
      #
      # @param dirs [Array<String>] directories
      # @return [String] shell variable lines
      # @api private
      def init_command_vars_for_powershell(dirs)
        [
          %{$dirs = @(#{dirs.map { |d| %{"#{d}"} }.join(", ")})},
          shell_var("root_path", config[:root_path]),
        ].join("\n")
      end

      # Load cookbook dependency resolver code, if required.
      #
      # (see Base#load_needed_dependencies!)
      def load_needed_dependencies!
        super
        if File.exist?(policyfile)
          debug("Policyfile found at #{policyfile}, using Policyfile to resolve cookbook dependencies")
          Cinc::Policyfile.load!(logger:)
        elsif File.exist?(berksfile)
          debug("Berksfile found at #{berksfile}, using Berkshelf to resolve cookbook dependencies")
          Cinc::Berkshelf.load!(logger:)
        end
      end

      # @return [String] contents of the install script
      # @api private
      def install_script_contents
        require "mixlib/install"
        installer = Mixlib::Install.new({
          product_name: config[:product_name],
          product_version: config[:product_version],
          channel: config[:channel].to_sym,
          install_command_options: {
            install_strategy: config[:install_strategy],
          },
        }.tap do |opts|
          opts[:shell_type] = :ps1 if powershell_shell?
          %i{platform platform_version architecture}.each do |key|
            opts[key] = config[key] if config[key]
          end

          unless windows_os?
            # omnitruck installer does not currently support a tmp dir option on windows
            opts[:install_command_options][:tmp_dir] = config[:root_path]
            opts[:install_command_options]["TMPDIR"] = config[:root_path]
          end

          if config[:download_url]
            opts[:install_command_options][:download_url_override] = config[:download_url]
            opts[:install_command_options][:checksum] = config[:checksum] if config[:checksum]
          end

          if instance.driver.cache_directory
            download_dir_option = windows_os? ? :download_directory : :cmdline_dl_dir
            opts[:install_command_options][download_dir_option] = instance.driver.cache_directory
          end

          proxies = {}.tap do |prox|
            %i{http_proxy https_proxy ftp_proxy no_proxy}.each do |key|
              prox[key] = config[key] if config[key]
            end

            # install.ps1 only supports http_proxy
            prox.delete_if { |p| %i{https_proxy ftp_proxy no_proxy}.include?(p) } if powershell_shell?
          end
          opts[:install_command_options].merge!(proxies)
        end)
        config[:cinc_omnibus_root] = installer.root
        if powershell_shell?
          installer.install_command
        else
          install_from_file(installer.install_command)
        end
      end

      def install_from_file(command)
        install_file = "#{config[:root_path]}/cinc-installer.sh"
        script = []
        script << "mkdir -p #{config[:root_path]}"
        script << "if [ $? -ne 0 ]; then"
        script << "  echo Kitchen config setting root_path: '#{config[:root_path]}' not creatable by regular user "
        script << "  exit 1"
        script << "fi"
        script << "cat > #{install_file} <<\"EOL\""
        script << command
        script << "EOL"
        script << "chmod +x #{install_file}"
        script << sudo(install_file)
        script.join("\n")
      end

      # Hook used in subclasses to indicate support for policyfiles.
      #
      # @abstract
      # @return [Boolean]
      # @api private
      def supports_policyfile?
        false
      end

      # @return [void]
      # @raise [UserError]
      # @api private
      def sanity_check_sandbox_options!
        if (config[:policyfile_path] || config[:policyfile]) && !File.exist?(policyfile)
          raise UserError, "policyfile_path set in config " \
            "(#{config[:policyfile_path]} could not be found. " \
            "Expected to find it at full path #{policyfile}."
        end
        if config[:berksfile_path] && !File.exist?(berksfile)
          raise UserError, "berksfile_path set in config " \
            "(#{config[:berksfile_path]} could not be found. " \
            "Expected to find it at full path #{berksfile}."
        end
        if File.exist?(policyfile) && !supports_policyfile?
          raise UserError, "policyfile detected, but provisioner " \
            "#{self.class.name} doesn't support Policyfiles. " \
            "Either use a different provisioner, or delete/rename " \
            "#{policyfile}."
        end
      end

      # Writes a configuration file to the sandbox directory.
      # @api private
      def prepare_config_rb
        data = default_config_rb.merge(config[config_filename.tr(".", "_").to_sym])
        data = data.merge(named_run_list: config[:named_run_list]) if config[:named_run_list]

        info("Preparing #{config_filename}")
        debug("Creating #{config_filename} from #{data.inspect}")

        File.open(File.join(sandbox_path, config_filename), "wb") do |file|
          file.write(format_config_file(data))
        end

        prepare_config_idempotency_check(data) if config[:enforce_idempotency]
      end

      # Writes a configuration file to the sandbox directory
      # to check for idempotency of the run.
      # @api private
      def prepare_config_idempotency_check(data)
        handler_filename = "cinc-client-fail-if-update-handler.rb"
        source = File.join(
          File.dirname(__FILE__), %w{.. .. .. support }, handler_filename
        )
        FileUtils.cp(source, File.join(sandbox_path, handler_filename))
        File.open(File.join(sandbox_path, "client_no_updated_resources.rb"), "wb") do |file|
          file.write(format_config_file(data))
          file.write("\n\n")
          file.write("handler_file = File.join(File.dirname(__FILE__), '#{handler_filename}')\n")
          file.write "Chef::Config.from_file(handler_file)\n"
        end
      end

      # Returns an Array of command line arguments for the cinc client.
      #
      # @return [Array<String>] an array of command line arguments
      # @api private
      def chef_args(_config_filename)
        raise "You must override in sub classes!"
      end

      # Returns a filename for the configuration file
      # defaults to client.rb
      #
      # @return [String] a filename
      # @api private
      def config_filename
        "client.rb"
      end

      # Gives the command used to run cinc
      # @api private
      def chef_cmd(base_cmd)
        if windows_os?
          separator = [
            "; if ($LastExitCode -ne 0) { ",
            "throw \"Command failed with exit code $LastExitCode.\" } ;",
          ].join
        else
          separator = " && "
        end
        chef_cmds(base_cmd).join(separator)
      end

      # Gives an array of commands
      # @api private
      def chef_cmds(base_cmd)
        cmds = []
        num_converges = config[:multiple_converge].to_i
        idempotency   = config[:enforce_idempotency]

        # Execute Cinc Client n-1 times, without exiting
        (num_converges - 1).times do
          cmds << wrapped_chef_cmd(base_cmd, config_filename)
        end

        # Append another execution with Windows specific Exit code helper or (for
        # idempotency check) a specific config file which assures no changed resources.
        cmds << unless idempotency
                  wrapped_chef_cmd(base_cmd, config_filename, append: last_exit_code)
                else
                  wrapped_chef_cmd(base_cmd, "client_no_updated_resources.rb", append: last_exit_code)
                end
        cmds
      end

      # Concatenate all arguments and wrap it with shell-specifics
      # @api private
      def wrapped_chef_cmd(base_cmd, configfile, append: "")
        args = []

        args << base_cmd
        args << chef_args(configfile)
        args << append

        shell_cmd = args.flatten.join(" ")
        shell_cmd = shell_cmd.prepend(reload_ps1_path) if windows_os?

        prefix_command(wrap_shell_code(shell_cmd))
      end

      # Builds a complete command given a variables String preamble and a file
      # containing shell code.
      #
      # @param vars [String] shell variables, as a String
      # @param file [String] file basename (without extension) containing
      #   shell code
      # @return [String] command
      # @api private
      def shell_code_from_file(vars, file)
        src_file = File.join(
          File.dirname(__FILE__),
          %w{.. .. .. support},
          file + (powershell_shell? ? ".ps1" : ".sh")
        )

        wrap_shell_code([vars, "", File.read(src_file)].join("\n"))
      end
    end
  end
end
