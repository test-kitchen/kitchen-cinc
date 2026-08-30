#
# Copyright (C) 2014, Fletcher Nichol
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

require_relative "../../spec_helper"

require "kitchen"
require "kitchen/provisioner/cinc_base"
require "fileutils"
require "mixlib/install"

describe Kitchen::Provisioner::CincBase do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(os_type: nil) }
  let(:driver)          { stub(cache_directory: nil) }
  let(:suite)           { stub(name: "fries") }

  let(:config) do
    { test_base_path: "/basist", kitchen_root: "/rooty" }
  end

  let(:instance) do
    stub(
      name: "coolbeans",
      logger: logger,
      suite: suite,
      platform: platform,
      driver: driver
    )
  end

  let(:provisioner) do
    Class.new(Kitchen::Provisioner::CincBase) do
      def calculate_path(path, _opts = {})
        "<calculated>/#{path}"
      end
    end.new(config).finalize_config!(instance)
  end

  describe "configuration" do
    it ":run_list defaults to an empty array" do
      _(provisioner[:run_list]).must_equal []
    end

    it ":attributes defaults to an empty hash" do
      _(provisioner[:attributes]).must_equal({})
    end

    it ":log_level defaults to auto" do
      _(provisioner[:log_level]).must_equal "auto"
    end

    it ":log_level is debug when in debug mode" do
      config[:debug] = true
      _(provisioner[:log_level]).must_equal "debug"
    end

    it ":log_file defaults to nil" do
      _(provisioner[:log_file]).must_be_nil
    end

    it ":cookbook_files_glob includes a metadata file" do
      _(provisioner[:cookbook_files_glob]).must_match(/,metadata.\{json,rb\}/)
    end

    it ":data_path uses calculate_path and is expanded" do
      _(provisioner[:data_path]).must_equal os_safe_root_path("/rooty/<calculated>/data")
    end

    it ":data_bags_path uses calculate_path and is expanded" do
      _(provisioner[:data_bags_path]).must_equal os_safe_root_path("/rooty/<calculated>/data_bags")
    end

    it ":environments_path uses calculate_path and is expanded" do
      _(provisioner[:environments_path]).must_equal os_safe_root_path("/rooty/<calculated>/environments")
    end

    it ":nodes_path uses calculate_path and is expanded" do
      _(provisioner[:nodes_path]).must_equal os_safe_root_path("/rooty/<calculated>/nodes")
    end

    it ":roles_path uses calculate_path and is expanded" do
      _(provisioner[:roles_path]).must_equal os_safe_root_path("/rooty/<calculated>/roles")
    end

    it ":clients_path uses calculate_path and is expanded" do
      _(provisioner[:clients_path]).must_equal os_safe_root_path("/rooty/<calculated>/clients")
    end

    it "...secret_key_path uses calculate_path and is expanded" do
      _(provisioner[:encrypted_data_bag_secret_key_path]).must_equal os_safe_root_path("/rooty/<calculated>/encrypted_data_bag_secret_key")
    end

    it ":product_name defaults to cinc" do
      _(provisioner[:product_name]).must_equal "cinc"
    end

    it ":product_version defaults to :latest" do
      _(provisioner[:product_version]).must_equal :latest
    end

    it ":channel defaults to :stable" do
      _(provisioner[:channel]).must_equal :stable
    end

    it ":platform default to nil" do
      _(provisioner[:platform]).must_be_nil
    end

    it ":platform_version default to nil" do
      _(provisioner[:platform_version]).must_be_nil
    end

    it ":architecture default to nil" do
      _(provisioner[:architecture]).must_be_nil
    end

    it ":download_url default to nil" do
      _(provisioner[:download_url]).must_be_nil
    end

    it ":checksum default to nil" do
      _(provisioner[:checksum]).must_be_nil
    end

    it ":retry_on_exit_code defaults to standard values" do
      _(provisioner[:retry_on_exit_code]).must_equal [35, 213]
    end
  end

  describe "deprecated chef_* config-key forwarding" do
    Kitchen::Provisioner::CincBase::CHEF_TO_CINC_KEYS.each do |chef_key, cinc_key|
      it "forwards #{chef_key} to #{cinc_key} when only the chef_* key is set" do
        config[chef_key] = "value-from-chef-key"
        _(provisioner[cinc_key]).must_equal "value-from-chef-key"
      end

      it "prefers #{cinc_key} when both #{chef_key} and #{cinc_key} are set" do
        config[chef_key] = "old-chef-value"
        config[cinc_key] = "new-cinc-value"
        _(provisioner[cinc_key]).must_equal "new-cinc-value"
      end

      it "registers #{chef_key} as a deprecated attribute" do
        _(Kitchen::Provisioner::CincBase.deprecated_attributes).must_include chef_key
      end
    end
  end

  describe "#install_command" do
    before do
      platform.stubs(:shell_type).returns("bourne")
    end

    let(:installer) { stub(root: "/rooty", install_command: "make_it_so") }

    let(:cmd) { provisioner.install_command }

    it "returns nil if :product_name is nil" do
      config[:product_name] = nil

      Mixlib::Install.expects(:new).never
      _(cmd).must_be_nil
    end


    describe "for product" do
      before do
        installer.expects(:root).at_least_once.returns("/opt/cinc")
        installer.expects(:install_command)
        config[:product_name] = "my_product"
      end

      it "will set the product name, version and channel" do
        config[:product_version] = "version"
        config[:channel] = "channel"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:product_name]).must_equal "my_product"
          _(opts[:product_version]).must_equal "version"
          _(opts[:channel]).must_equal :channel
        end.returns(installer)
        cmd
      end

      it "will set the architecture if given" do
        config[:architecture] = "architecture"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:architecture]).must_equal "architecture"
        end.returns(installer)
        cmd
      end

      it "will set the platform if given" do
        config[:platform] = "platform"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:platform]).must_equal "platform"
        end.returns(installer)
        cmd
      end

      it "will set the platform_version if given" do
        config[:platform_version] = "platform_version"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:platform_version]).must_equal "platform_version"
        end.returns(installer)
        cmd
      end

      it "will omit the architecture if not given" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts.key?(:architecture)).must_equal false
        end.returns(installer)
        cmd
      end

      it "will omit the platform if not given" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts.key?(:platform)).must_equal false
        end.returns(installer)
        cmd
      end

      it "will omit the platform_version if not given" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts.key?(:platform_version)).must_equal false
        end.returns(installer)
        cmd
      end

      it "will use stable channel when none specified" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:channel]).must_equal :stable
        end.returns(installer)
        cmd
      end

      it "will set install_strategy to once when not given" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:install_strategy]).must_equal "once"
        end.returns(installer)
        cmd
      end

      it "will set install_strategy when given" do
        config[:install_strategy] = "always"
        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:install_strategy]).must_equal "always"
        end.returns(installer)
        cmd
      end

      it "will set the download_url and checksum if given" do
        config[:download_url] = "http://url/path"
        config[:checksum] = "abcd"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:download_url_override]).must_equal "http://url/path"
          _(opts[:install_command_options][:checksum]).must_equal "abcd"
        end.returns(installer)
        cmd
      end

      it "will set the http_proxy and https_proxy if given" do
        config[:http_proxy] = "http://url/path:8000"
        config[:https_proxy] = "http://url/path:8000"

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:http_proxy]).must_equal "http://url/path:8000"
          _(opts[:install_command_options][:https_proxy]).must_equal "http://url/path:8000"
        end.returns(installer)
        cmd
      end

      it "will set the http_proxy only for powershell" do
        config[:http_proxy] = "http://url/path:8000"
        config[:https_proxy] = "http://url/path:8000"
        platform.stubs(:shell_type).returns("powershell")
        platform.stubs(:os_type).returns("windows")

        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:http_proxy]).must_equal "http://url/path:8000"
          _(opts[:install_command_options][:https_proxy]).must_be_nil
        end.returns(installer)
        cmd
      end

      it "will not set proxies when not given" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:install_command_options][:http_proxy]).must_be_nil
        end.returns(installer)
        cmd
      end

      describe "when driver implements the cache_directory" do
        describe "for windows" do
          before { driver.stubs(:cache_directory).returns('$env:TEMP\\dummy\\place') }

          it "will have the set behavior on windows" do
            platform.stubs(:shell_type).returns("powershell")
            platform.stubs(:os_type).returns("windows")

            Mixlib::Install.expects(:new).with do |opts|
              _(opts[:install_command_options][:download_directory]).must_equal '$env:TEMP\\dummy\\place'
            end.returns(installer)
            cmd
          end
        end

        describe "for shell" do
          before { driver.stubs(:cache_directory).returns("/tmp") }

          it "will have the set behavior on non-windows" do
            Mixlib::Install.expects(:new).with do |opts|
              _(opts[:install_command_options][:cmdline_dl_dir]).must_equal "/tmp"
            end.returns(installer)
            cmd
          end
        end
      end
    end

    describe "when install_strategy is skipped" do
      before do
        config[:product_name] = "my_product"
        config[:install_strategy] = "skip"
      end

      it "will not return installer when install_strategy is set to skip" do
        Mixlib::Install.expects(:new).never
        cmd
      end
    end

    describe "for bourne shells" do
      before do
        config[:product_name] = "my_product"
        installer.expects(:root).at_least_once.returns("/opt/cinc")
        installer.expects(:install_command).returns("my_install_command")
      end

      it "does not pass shell type for product based command" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts.key?(:shell_type)).must_equal false
        end.returns(installer)
        cmd
      end

      it "writes the installer into root_path" do
        config[:root_path] = "/tmp/kitchen"
        Mixlib::Install.stubs(:new).returns(installer)

        _(cmd).must_include "mkdir -p /tmp/kitchen\n"
        _(cmd).must_include %{cat > /tmp/kitchen/cinc-installer.sh <<"EOL"}
        _(cmd).must_include "chmod +x /tmp/kitchen/cinc-installer.sh"
      end

      it "shell-escapes a root_path containing spaces" do
        config[:root_path] = "/tmp/kitchen dir"
        Mixlib::Install.stubs(:new).returns(installer)

        _(cmd).must_include "mkdir -p /tmp/kitchen\\ dir\n"
        _(cmd).must_include %{cat > /tmp/kitchen\\ dir/cinc-installer.sh <<"EOL"}
        _(cmd).must_include "chmod +x /tmp/kitchen\\ dir/cinc-installer.sh"
        _(cmd).wont_include "mkdir -p /tmp/kitchen dir\n"
      end
    end

    describe "for powershell shells on windows os types" do
      before do
        config[:product_name] = "my_product"
        installer.expects(:root).at_least_once.returns("/opt/cinc")
        installer.expects(:install_command)
        platform.stubs(:shell_type).returns("powershell")
        platform.stubs(:os_type).returns("windows")
      end

      it "passes ps1 shell type for product based command" do
        Mixlib::Install.expects(:new).with do |opts|
          _(opts[:shell_type]).must_equal :ps1
        end.returns(installer)
        cmd
      end
    end
  end

  describe "#init_command" do
    let(:cmd) { provisioner.init_command }

    describe "common behavior" do
      before { platform.stubs(:shell_type).returns("fake") }

      it "prefixes the whole command with the command_prefix if set" do
        config[:command_prefix] = "my_prefix"

        _(cmd).must_match(/\Amy_prefix /)
      end

      it "does not prefix the command if command_prefix is not set" do
        config[:command_prefix] = nil

        _(cmd).wont_match(/\Amy_prefix /)
      end
    end

    describe "for bourne shells" do
      before { platform.stubs(:shell_type).returns("bourne") }

      it "uses bourne shell" do
        _(cmd).must_match(/\Ash -c '$/)
        _(cmd).must_match(/'\Z/)
      end

      it "ends with a single quote" do
        _(cmd).must_match(/'\Z/)
      end

      it "exports http_proxy & HTTP_PROXY when :http_proxy is set" do
        config[:http_proxy] = "http://proxy"

        _(cmd.lines.to_a[1..2]).must_equal([
                                          %{http_proxy="http://proxy"; export http_proxy\n},
                                          %{HTTP_PROXY="http://proxy"; export HTTP_PROXY\n},
                                        ])
      end

      it "exports https_proxy & HTTPS_PROXY when :https_proxy is set" do
        config[:https_proxy] = "https://proxy"

        _(cmd.lines.to_a[1..2]).must_equal([
                                          %{https_proxy="https://proxy"; export https_proxy\n},
                                          %{HTTPS_PROXY="https://proxy"; export HTTPS_PROXY\n},
                                        ])
      end

      it "exports all http proxy variables when both are set" do
        config[:http_proxy] = "http://proxy"
        config[:https_proxy] = "https://proxy"

        _(cmd.lines.to_a[1..4]).must_equal([
                                          %{http_proxy="http://proxy"; export http_proxy\n},
                                          %{HTTP_PROXY="http://proxy"; export HTTP_PROXY\n},
                                          %{https_proxy="https://proxy"; export https_proxy\n},
                                          %{HTTPS_PROXY="https://proxy"; export HTTPS_PROXY\n},
                                        ])
      end

      it "prepends sudo for rm when :sudo is set" do
        config[:sudo] = true

        _(cmd).must_match regexify(%{sudo_rm="sudo -E rm"})
      end

      it "does not sudo for sh commands when :sudo is falsey" do
        config[:sudo] = false

        _(cmd).must_match regexify(%{sudo_rm="rm"})
      end

      it "sets chef component dirs for deletion" do
        config[:root_path] = "/route"
        dirs = %w{
          /route/clients /route/cookbooks /route/data /route/data_bags
          /route/encrypted_data_bag_secret /route/environments /route/roles
        }.join(" ")

        _(cmd).must_match regexify(%{dirs="#{dirs}"})
      end

      it "sets the root_path from :root_path" do
        config[:root_path] = "RIGHT_HERE"

        _(cmd).must_match regexify(%{root_path="RIGHT_HERE"})
      end
    end

    describe "for powershell shells on windows os types" do
      before do
        platform.stubs(:shell_type).returns("powershell")
        platform.stubs(:os_type).returns("windows")
      end

      def decode_powershell_command(cmd)
        if cmd.match(/powershell.*-EncodedCommand\s+(.+)$/)
          encoded = $1.strip
          utf16le = encoded.unpack("m0").first
          utf16le.encode(Encoding::UTF_8, Encoding::UTF_16LE)
        else
          cmd
        end
      end

      it "exports http_proxy & HTTP_PROXY when :http_proxy is set" do
        config[:http_proxy] = "http://proxy"

        decoded = decode_powershell_command(cmd)
        _(decoded.lines.to_a[0..1]).must_equal([
                                          %{$env:http_proxy = "http://proxy"\n},
                                          %{$env:HTTP_PROXY = "http://proxy"\n},
                                        ])
      end

      it "exports https_proxy & HTTPS_PROXY when :https_proxy is set" do
        config[:https_proxy] = "https://proxy"

        decoded = decode_powershell_command(cmd)
        _(decoded.lines.to_a[0..1]).must_equal([
                                          %{$env:https_proxy = "https://proxy"\n},
                                          %{$env:HTTPS_PROXY = "https://proxy"\n},
                                        ])
      end

      it "exports all http proxy variables when both are set" do
        config[:http_proxy] = "http://proxy"
        config[:https_proxy] = "https://proxy"

        decoded = decode_powershell_command(cmd)
        _(decoded.lines.to_a[0..3]).must_equal([
                                          %{$env:http_proxy = "http://proxy"\n},
                                          %{$env:HTTP_PROXY = "http://proxy"\n},
                                          %{$env:https_proxy = "https://proxy"\n},
                                          %{$env:HTTPS_PROXY = "https://proxy"\n},
                                        ])
      end

      it "sets chef component dirs for deletion" do
        config[:root_path] = '\\route'
        dirs = %w{ clients cookbooks data data_bags encrypted_data_bag_secret
                   environments roles
                 }.map do |dir|
                   "\\route\\#{dir}"
                 end.join(", ")

        cmd.include? "$dirs = @(#{dirs})"
      end

      it "sets the root_path from :root_path" do
        config[:root_path] = "RIGHT_HERE"

        decoded = decode_powershell_command(cmd)
        _(decoded).must_match regexify(%{$root_path = "RIGHT_HERE"})
      end
    end
  end

  describe "#create_sandbox" do
    before do
      @root = Dir.mktmpdir
      config[:kitchen_root] = @root
    end

    after do
      FileUtils.remove_entry(@root)
      begin
        provisioner.cleanup_sandbox
      rescue # rubocop:disable Lint/HandleExceptions
      end
    end

    let(:provisioner) do
      Class.new(Kitchen::Provisioner::CincBase) do
        default_config :generic_rb, {}

        def create_sandbox
          super

          data = default_config_rb.merge(config[:generic_rb])
          File.open(File.join(sandbox_path, "generic.rb"), "wb") do |file|
            file.write(format_config_file(data))
          end
        end
      end.new(config).finalize_config!(instance)
    end

    describe "json file" do
      let(:json) { JSON.parse(File.read(sandbox_path("dna.json"))) }

      it "creates a json file with node attributes" do
        config[:attributes] = { "one" => { "two" => "three" } }
        provisioner.create_sandbox

        _(json["one"]).must_equal("two" => "three")
      end

      it "creates a json file with run_list" do
        config[:run_list] = %w{alpha bravo charlie}
        provisioner.create_sandbox

        _(json["run_list"]).must_equal %w{alpha bravo charlie}
      end

      it "creates a json file with an empty run_list" do
        config[:run_list] = []
        provisioner.create_sandbox

        _(json["run_list"]).must_equal []
      end

      it "logs a message on info" do
        provisioner.create_sandbox

        _(logged_output.string).must_match info_line("Preparing dna.json")
      end

      it "logs a message on debug" do
        config[:run_list] = ["yo"]
        provisioner.create_sandbox

        _(logged_output.string).must_match debug_line(%(Creating dna.json from #{{run_list: ["yo"]}.to_s}))
      end
    end

    it "creates a cache directory" do
      provisioner.create_sandbox

      _(sandbox_path("cache").directory?).must_equal true
    end

    %w{data data_bags environments nodes roles clients}.each do |thing|
      describe "#{thing} files" do
        before do
          create_files_under("#{config[:kitchen_root]}/my_#{thing}")
          config[:"#{thing}_path"] = "#{config[:kitchen_root]}/my_#{thing}"
        end

        it "skips directory creation if :#{thing}_path is not set" do
          config[:"#{thing}_path"] = nil
          provisioner.create_sandbox

          _(sandbox_path(thing).directory?).must_equal false
        end

        it "copies tree from :#{thing}_path into sandbox" do
          provisioner.create_sandbox

          _(sandbox_path("#{thing}/alpha.txt").file?).must_equal true
          _(File.read(sandbox_path("#{thing}/alpha.txt"))).must_equal "stuff"
          _(sandbox_path("#{thing}/sub").directory?).must_equal true
          _(sandbox_path("#{thing}/sub/bravo.txt").file?).must_equal true
          _(File.read(sandbox_path("#{thing}/sub/bravo.txt"))).must_equal "junk"
        end

        it "logs a message on info" do
          provisioner.create_sandbox

          _(logged_output.string).must_match info_line("Preparing #{thing}")
        end

        it "logs a message on debug" do
          provisioner.create_sandbox

          _(logged_output.string).must_match debug_line(
            "Using #{thing} from #{config[:kitchen_root]}/my_#{thing}"
          )
        end
      end
    end

    describe "secret files" do
      before do
        config[:encrypted_data_bag_secret_key_path] =
          "#{config[:kitchen_root]}/my_secret"
        File.open("#{config[:kitchen_root]}/my_secret", "wb") do |file|
          file.write("p@ss")
        end
      end

      it "skips file if :encrypted_data_bag_secret_key_path is not set" do
        config[:encrypted_data_bag_secret_key_path] = nil
        provisioner.create_sandbox

        _(sandbox_path("encrypted_data_bag_secret").file?).must_equal false
      end

      it "copies file from :encrypted_data_bag_secret_key_path into sandbox" do
        provisioner.create_sandbox

        _(sandbox_path("encrypted_data_bag_secret").file?).must_equal true
        _(File.read(sandbox_path("encrypted_data_bag_secret"))).must_equal "p@ss"
      end

      it "logs a message on info" do
        provisioner.create_sandbox

        _(logged_output.string).must_match info_line("Preparing secret")
      end

      it "logs a message on debug" do
        provisioner.create_sandbox

        _(logged_output.string).must_match debug_line(
          "Using secret from #{config[:kitchen_root]}/my_secret"
        )
      end
    end

    describe "cookbooks" do
      let(:kitchen_root) { config[:kitchen_root] }

      describe "with a cookbooks/ directory under kitchen_root" do
        it "copies cookbooks/" do
          create_cookbook("#{kitchen_root}/cookbooks/epache")
          create_cookbook("#{kitchen_root}/cookbooks/jahva")
          provisioner.create_sandbox

          _(sandbox_path("cookbooks/epache").directory?).must_equal true
          _(sandbox_path("cookbooks/epache/recipes/default.rb").file?).must_equal true
          _(sandbox_path("cookbooks/jahva").directory?).must_equal true
          _(sandbox_path("cookbooks/jahva/recipes/default.rb").file?).must_equal true
        end

        it "copies from kitchen_root as cookbook if it contains metadata.rb" do
          File.open("#{kitchen_root}/metadata.rb", "wb") do |file|
            file.write("name 'wat'")
          end
          create_cookbook("#{kitchen_root}/cookbooks/bk")
          provisioner.create_sandbox

          _(sandbox_path("cookbooks/bk").directory?).must_equal true
          _(sandbox_path("cookbooks/wat").directory?).must_equal true
          _(sandbox_path("cookbooks/wat/metadata.rb").file?).must_equal true
        end

        it "copies site-cookbooks/ if it exists" do
          create_cookbook("#{kitchen_root}/cookbooks/upstream")
          create_cookbook("#{kitchen_root}/site-cookbooks/mine")
          provisioner.create_sandbox

          _(sandbox_path("cookbooks/upstream").directory?).must_equal true
          _(sandbox_path("cookbooks/mine").directory?).must_equal true
          _(sandbox_path("cookbooks/mine/attributes/all.rb").file?).must_equal true
        end

        it "logs a message on info for cookbooks/ directory" do
          create_cookbook("#{kitchen_root}/cookbooks/epache")
          provisioner.create_sandbox

          _(logged_output.string).must_match info_line(
            "Preparing cookbooks from project directory"
          )
        end

        it "logs a message on debug for cookbooks/ directory" do
          create_cookbook("#{kitchen_root}/cookbooks/epache")
          provisioner.create_sandbox

          _(logged_output.string).must_match debug_line(
            "Using cookbooks from #{kitchen_root}/cookbooks"
          )
        end

        it "logs a message on info for site-cookbooks/ directory" do
          create_cookbook("#{kitchen_root}/cookbooks/epache")
          create_cookbook("#{kitchen_root}/site-cookbooks/mine")
          provisioner.create_sandbox

          _(logged_output.string).must_match info_line(
            "Preparing site-cookbooks from project directory"
          )
        end

        it "logs a message on debug for site-cookbooks/ directory" do
          create_cookbook("#{kitchen_root}/cookbooks/epache")
          create_cookbook("#{kitchen_root}/site-cookbooks/mine")
          provisioner.create_sandbox

          _(logged_output.string).must_match debug_line(
            "Using cookbooks from #{kitchen_root}/site-cookbooks"
          )
        end
      end

      describe "with a cookbook as the project" do
        before do
          File.open("#{kitchen_root}/metadata.rb", "wb") do |file|
            file.write("name 'wat'")
          end
        end

        it "copies from kitchen_root as cookbook if it contains metadata.rb" do
          provisioner.create_sandbox

          _(sandbox_path("cookbooks/wat").directory?).must_equal true
          _(sandbox_path("cookbooks/wat/metadata.rb").file?).must_equal true
        end

        it "logs a message on info" do
          provisioner.create_sandbox

          _(logged_output.string).must_match info_line(
            "Preparing current project directory as a cookbook"
          )
        end

        it "logs a message on debug" do
          provisioner.create_sandbox

          _(logged_output.string).must_match debug_line(
            "Using metadata.rb from #{kitchen_root}/metadata.rb"
          )
        end

        it "raises a UserError is name cannot be determined from metadata.rb" do
          File.open("#{kitchen_root}/metadata.rb", "wb") do |file|
            file.write("nameeeeee 'wat'")
          end

          _ { provisioner.create_sandbox }.must_raise Kitchen::UserError
        end
      end

      describe "with no referenced cookbooks" do
        it "makes a fake cookbook" do
          name = File.basename(@root)
          provisioner.create_sandbox

          _(sandbox_path("cookbooks/#{name}").directory?).must_equal true
          _(sandbox_path("cookbooks/#{name}/metadata.rb").file?).must_equal true
          _(File.read(sandbox_path("cookbooks/#{name}/metadata.rb"))).must_equal %{name "#{name}"\n}
        end

        it "logs a warning" do
          provisioner.create_sandbox

          _(logged_output.string).must_match regexify(
            "Berksfile, cookbooks/, or metadata.rb not found",
            :partial_line
          )
        end
      end

      describe "with a Policyfile under kitchen_root" do
        let(:policyfile_path) { "#{kitchen_root}/Policyfile.rb" }
        let(:policyfile_lock_path) { "#{kitchen_root}/Policyfile.lock.json" }
        let(:resolver) do
          stub(compile: true, resolve: true, lockfile: policyfile_lock_path)
        end

        describe "with the default name `Policyfile.rb`" do
          before do
            File.open("#{kitchen_root}/Policyfile.rb", "wb") do |file|
              file.write(<<~POLICYFILE)
                name 'wat'
                run_list 'wat'
                cookbook 'wat'
              POLICYFILE
            end
            File.open("#{kitchen_root}/Policyfile.lock.json", "wb") do |file|
              file.write(<<~POLICYFILE)
                {
                  "name": "wat"
                }
              POLICYFILE
            end
            Kitchen::Provisioner::Cinc::Policyfile.stubs(:new).returns(resolver)
          end

          describe "when using a provisioner that doesn't support policyfiles" do
            it "raises a UserError" do
              _ { provisioner.create_sandbox }.must_raise Kitchen::UserError
            end
          end

          describe "when the cinc executable is in the PATH" do
            before do
              Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
              provisioner.stubs(:supports_policyfile?).returns(true)
            end

            it "logs on debug that it autodetected the policyfile" do
              provisioner

              _(logged_output.string).must_match debug_line(
                "Policyfile found at #{kitchen_root}/Policyfile.rb, " \
                "using Policyfile to resolve cookbook dependencies"
              )
            end

            it "uses uses the policyfile to resolve dependencies" do
              resolver.expects(:compile)
              resolver.expects(:resolve)

              provisioner.create_sandbox
            end

            it "uses Kitchen.mutex for resolving" do
              Kitchen.mutex.expects(:synchronize).twice

              provisioner.create_sandbox
            end

            it "injects policyfile configuration into the dna.json" do
              provisioner.create_sandbox

              dna_json_file = File.join(provisioner.sandbox_path, "dna.json")
              dna_json_data = JSON.parse(File.read(dna_json_file))

              expected = {
                "policy_name" => "wat",
                "policy_group" => "local",
              }

              _(dna_json_data).must_equal(expected)
            end
          end
        end

        describe "with a custom policyfile_path" do
          let(:config) do
            {
              policyfile_path: "foo-policy.rb",
              test_base_path: "/basist",
              kitchen_root: "/rooty",
            }
          end

          before do
            Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
            Kitchen::Provisioner::Cinc::Policyfile.stubs(:new).returns(resolver)
            provisioner.stubs(:supports_policyfile?).returns(true)
          end

          describe "when the policyfile exists" do
            let(:policyfile_path) { "#{kitchen_root}/foo-policy.rb" }
            let(:policyfile_lock_path) { "#{kitchen_root}/foo-policy.lock.json" }

            before do
              File.open(policyfile_path, "wb") do |file|
                file.write(<<~POLICYFILE)
                  name 'wat'
                  run_list 'wat'
                  cookbook 'wat'
                POLICYFILE
              end
              File.open(policyfile_lock_path, "wb") do |file|
                file.write(<<~POLICYFILE)
                  {
                    "name": "wat"
                  }
                POLICYFILE
              end
            end

            it "uses uses the policyfile to resolve dependencies" do
              Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
              resolver.expects(:compile)
              resolver.expects(:resolve)

              provisioner.create_sandbox
            end

            it "passes the correct path to the policyfile resolver" do
              Kitchen::Provisioner::Cinc::Policyfile
                .expects(:new)
                .with(policyfile_path, instance_of(String), anything)
                .returns(resolver)

              Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
              resolver.expects(:compile)
              resolver.expects(:resolve)

              provisioner.create_sandbox
            end
          end
          describe "when the policyfile doesn't exist" do
            it "raises a UserError" do
              _ { provisioner.create_sandbox }.must_raise Kitchen::UserError
            end
          end
          describe "when the policyfile lock doesn't exist" do
            before do
              File.open("#{kitchen_root}/Policyfile.rb", "wb") do |file|
                file.write(<<~POLICYFILE)
                  name 'wat'
                  run_list 'wat'
                  cookbook 'wat'
                POLICYFILE
              end

              it "runs `cinc install` to generate the lock" do
                resolver.expects(:compile)
                provisioner.create_sandbox
              end
            end
          end
        end
        describe "with a fallback policyfile" do
          let(:config) do
            {
              policyfile: "foo-policy.rb",
              test_base_path: "/basist",
              kitchen_root: "/rooty",
            }
          end

          before do
            Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
            Kitchen::Provisioner::Cinc::Policyfile.stubs(:new).returns(resolver)
            provisioner.stubs(:supports_policyfile?).returns(true)
          end

          describe "when the policyfile exists" do
            let(:policyfile_path) { "#{kitchen_root}/foo-policy.rb" }
            let(:policyfile_lock_path) { "#{kitchen_root}/foo-policy.lock.json" }

            before do
              File.open(policyfile_path, "wb") do |file|
                file.write(<<~POLICYFILE)
                  name 'wat'
                  run_list 'wat'
                  cookbook 'wat'
                POLICYFILE
              end
              File.open(policyfile_lock_path, "wb") do |file|
                file.write(<<~POLICYFILE)
                  {
                    "name": "wat"
                  }
                POLICYFILE
              end
            end

            it "uses uses the policyfile to resolve dependencies" do
              Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
              resolver.expects(:compile)
              resolver.expects(:resolve)

              provisioner.create_sandbox
            end

            it "passes the correct path to the policyfile resolver" do
              Kitchen::Provisioner::Cinc::Policyfile
                .expects(:new)
                .with(policyfile_path, instance_of(String), anything)
                .returns(resolver)

              Kitchen::Provisioner::Cinc::Policyfile.stubs(:load!)
              resolver.expects(:compile)
              resolver.expects(:resolve)

              provisioner.create_sandbox
            end
          end
          describe "when the policyfile doesn't exist" do
            it "raises a UserError" do
              _ { provisioner.create_sandbox }.must_raise Kitchen::UserError
            end
          end
        end
      end

      describe "with a Berksfile under kitchen_root" do
        let(:resolver) { stub(resolve: true) }

        before do
          File.open("#{kitchen_root}/Berksfile", "wb") do |file|
            file.write("cookbook 'wat'")
          end
          Kitchen::Provisioner::Cinc::Berkshelf.stubs(:new).returns(resolver)
        end

        it "raises a UserError if Berkshelf library can't be loaded" do
          Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load_berkshelf!).with do
            raise Kitchen::UserError, "Load failed"
          end
          _ { provisioner }.must_raise Kitchen::UserError
        end

        it "logs on debug that Berkshelf is loading" do
          Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
          provisioner

          _(logged_output.string).must_match debug_line(
            "Berksfile found at #{kitchen_root}/Berksfile, using Berkshelf to resolve cookbook dependencies"
          )
        end

        it "uses Berkshelf" do
          Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
          resolver.expects(:resolve)

          provisioner.create_sandbox
        end

        it "uses Kitchen.mutex for resolving" do
          Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
          Kitchen.mutex.expects(:synchronize)

          provisioner.create_sandbox
        end

        describe "with a custom berksfile_path" do
          let(:config) do
            {
              berksfile_path: "foo-berks.rb",
              test_base_path: "/basist",
              kitchen_root: "/rooty",
            }
          end

          before do
            File.open("#{kitchen_root}/foo-berks.rb", "wb") do |file|
              file.write("cookbook 'wat'")
            end
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:new).returns(resolver)
          end

          it "logs on debug that Berkshelf is loading" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            provisioner

            _(logged_output.string).must_match debug_line(
              "Berksfile found at #{kitchen_root}/foo-berks.rb, using Berkshelf to resolve cookbook dependencies"
            )
          end

          it "uses Berkshelf" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            resolver.expects(:resolve)

            provisioner.create_sandbox
          end

          it "uses Kitchen.mutex for resolving" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            Kitchen.mutex.expects(:synchronize)

            provisioner.create_sandbox
          end
        end

        describe "with a custom berksfile_path with a relative path" do
          let(:config) do
            {
              berksfile_path: "../foo-berks.rb",
              test_base_path: "/basist",
              kitchen_root: "/rooty",
            }
          end

          before do
            File.open(File.expand_path("../foo-berks.rb", kitchen_root), "wb") do |file|
              file.write("cookbook 'wat'")
            end
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:new).returns(resolver)
          end

          it "logs on debug that Berkshelf is loading" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            provisioner

            _(logged_output.string).must_match debug_line(
              "Berksfile found at #{File.expand_path("../foo-berks.rb", kitchen_root)}, using Berkshelf to resolve cookbook dependencies"
            )
          end

          it "uses Berkshelf" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            resolver.expects(:resolve)

            provisioner.create_sandbox
          end

          it "uses Kitchen.mutex for resolving" do
            Kitchen::Provisioner::Cinc::Berkshelf.stubs(:load!)
            Kitchen.mutex.expects(:synchronize)

            provisioner.create_sandbox
          end
        end
      end

      describe "filtering cookbooks files" do
        it "retains all useful cookbook files" do
          create_full_cookbook("#{kitchen_root}/cookbooks/full")
          provisioner.create_sandbox

          full_cookbook_files.each do |file|
            _(sandbox_path("cookbooks/full/#{file}").file?).must_equal true
          end
        end

        it "strips extra cookbook files" do
          extras = %w{
            .gitignore tmp/librarian chefignore .git/info/excludes
            cookbooks/another/metadata.rb CONTRIBUTING.md metadata.py
          }

          create_full_cookbook("#{kitchen_root}/cookbooks/full")
          extras.each do |file|
            create_file("#{kitchen_root}/cookbooks/full/#{file}")
          end
          provisioner.create_sandbox

          extras.each do |file|
            _(sandbox_path("cookbooks/full/#{file}").file?).must_equal false
          end
        end

        it "logs on info" do
          create_full_cookbook("#{kitchen_root}/cookbooks/full")
          provisioner.create_sandbox

          _(logged_output.string).must_match info_line(
            "Removing non-cookbook files before transfer"
          )
        end
      end

      describe "Chef config files" do
        let(:file) do
          File.read(sandbox_path("generic.rb")).lines.map(&:chomp)
        end

        it "#create_sandbox creates a generic.rb" do
          provisioner.create_sandbox

          _(sandbox_path("generic.rb").file?).must_equal true
        end

        describe "defaults" do
          before { provisioner.create_sandbox }

          it "sets node_name to the instance name" do
            _(file).must_include %{node_name "#{instance.name}"}
          end

          it "sets checksum_path" do
            _(file).must_include %{checksum_path "/tmp/kitchen/checksums"}
          end

          it "sets file_backup_path" do
            _(file).must_include %{file_backup_path "/tmp/kitchen/backup"}
          end

          it "sets cookbook_path" do
            _(file).must_include %{cookbook_path } +
              %{["/tmp/kitchen/cookbooks", "/tmp/kitchen/site-cookbooks"]}
          end

          it "sets data_bag_path" do
            _(file).must_include %{data_bag_path "/tmp/kitchen/data_bags"}
          end

          it "sets environment_path" do
            _(file).must_include %{environment_path "/tmp/kitchen/environments"}
          end

          it "sets node_path" do
            _(file).must_include %{node_path "/tmp/kitchen/nodes"}
          end

          it "sets role_path" do
            _(file).must_include %{role_path "/tmp/kitchen/roles"}
          end

          it "sets client_path" do
            _(file).must_include %{client_path "/tmp/kitchen/clients"}
          end

          it "sets user_path" do
            _(file).must_include %{user_path "/tmp/kitchen/users"}
          end

          it "sets validation_key" do
            _(file).must_include %{validation_key "/tmp/kitchen/validation.pem"}
          end

          it "sets client_key" do
            _(file).must_include %{client_key "/tmp/kitchen/client.pem"}
          end

          it "sets chef_server_url" do
            _(file).must_include %{chef_server_url "http://127.0.0.1:8889"}
          end

          it "sets encrypted_data_bag_secret" do
            _(file).must_include %{encrypted_data_bag_secret } +
              %{"/tmp/kitchen/encrypted_data_bag_secret"}
          end

          it "disables deprecation warnings" do
            _(file).must_include %{treat_deprecation_warnings_as_errors false}
          end
        end

        it "supports overwriting defaults" do
          config[:generic_rb] = {
            node_name: "eagles",
            user_path: "/a/b/c/u",
            chef_server_url: "https://wherever.io",
          }
          provisioner.create_sandbox

          _(file).must_include %{node_name "eagles"}
          _(file).must_include %{user_path "/a/b/c/u"}
          _(file).must_include %{chef_server_url "https://wherever.io"}
        end

        it " supports adding new configuration" do
          config[:generic_rb] = {
            dark_secret: "golang",
          }
          provisioner.create_sandbox

          _(file).must_include %{dark_secret "golang"}
        end
      end

      def create_cookbook(path)
        %w{metadata.rb attributes/all.rb recipes/default.rb}.each do |file|
          create_file(File.join(path, file))
        end
      end

      def full_cookbook_files
        %w{
          README.org metadata.rb attributes/all.rb definitions/def.rb
          files/default/config.conf libraries/one.rb libraries/two.rb
          providers/sweet.rb recipes/default.rb resources/sweet.rb
          templates/ubuntu/12.04/nginx.conf.erb
        }
      end

      def create_full_cookbook(path)
        full_cookbook_files.each { |file| create_file(File.join(path, file)) }
      end

      def create_file(path)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "wb") { |f| f.write(path) }
      end
    end

    def sandbox_path(path)
      Pathname.new(provisioner.sandbox_path).join(path)
    end

    def create_files_under(path)
      FileUtils.mkdir_p(File.join(path, "sub"))
      File.open(File.join(path, "alpha.txt"), "wb") do |file|
        file.write("stuff")
      end
      File.open(File.join(path, "sub", "bravo.txt"), "wb") do |file|
        file.write("junk")
      end
    end

    def info_line(msg)
      /^I, .* : #{Regexp.escape(msg)}$/
    end

    def debug_line(msg)
      /^D, .* : #{Regexp.escape(msg)}$/
    end
  end

  describe "#chef_cmds" do
    before do
      provisioner.singleton_class.send(:public, :chef_cmds)

      platform.stubs(:os_type).returns("unix")
      platform.stubs(:shell_type).returns("bash")

      provisioner.stubs(:chef_args).returns([
        "--config /root/path/solo.rb",
        "--log_level auto",
        "--force-formatter",
        "--no-color",
        "--json-attributes dna.json",
      ])
    end

    describe "without :multiple_converge or :enforce_idempotency" do
      before do
        config[:multiple_converge] = 1
        config[:enforce_idempotency] = false
      end

      it "only includes one chef run" do
        provisioner.chef_cmds("cinc-bin").one?
      end
    end

    describe "with :multiple_converge = 2" do
      before do
        config[:multiple_converge] = 2
        config[:enforce_idempotency] = false
      end

      it "includes exactly two chef runs" do
        provisioner.chef_cmds("cinc-bin").count == 2
      end
    end

    describe "with :multiple_converge = 2 and :enforce_idempotency" do
      before do
        config[:multiple_converge] = 2
        config[:enforce_idempotency] = true
      end

      it "includes the config for idempotency on last run" do
        provisioner.chef_cmds("cinc-bin").last.include? "client_no_updated_resources.rb"
      end
    end

    describe "on Windows instances" do
      before do
        platform.stubs(:os_type).returns("windows")
        platform.stubs(:shell_type).returns("powershell")
      end

      describe "with :multiple_converge = 2" do
        before do
          config[:multiple_converge] = 2
          config[:enforce_idempotency] = true
        end

        it "only includes `exit` once" do
          provisioner.chef_cmds("cinc-bin").join("\n").scan("exit $LastExitCode").one?
        end

        it "only includes `exit` on last command" do
          provisioner.chef_cmds("cinc-bin").last.include? "exit $LastExitCode"
        end
      end
    end
  end

  describe "#wrapped_chef_cmd" do
    before do
      provisioner.singleton_class.send(:public, :wrapped_chef_cmd)
      platform.stubs(:shell_type).returns("bash")

      provisioner.stubs(:chef_args).returns([
        "--config /root/path/solo.rb",
        "--log_level auto",
        "--force-formatter",
        "--no-color",
        "--json-attributes dna.json",
      ])
    end

    let(:normal_call) { provisioner.wrapped_chef_cmd("cinc_bin", "individual_config.rb") }
    let(:appended_call) { provisioner.wrapped_chef_cmd("cinc_bin", "individual_config.rb", append: "; echo $?") }

    it "includes the base_cmd" do
      normal_call.include? "cinc_bin"
    end

    it "calls #chef_args" do
      normal_call.include? "--force-formatter"
      normal_call.include? "--json-attributes dna.json"
    end

    it "ends includes the config file name" do
      normal_call.include? "individual_config.rb"
    end

    it "appends a string, if given" do
      appended_call.include? "; echo $?"
    end

    describe "on Windows instances" do
      before do
        platform.stubs(:os_type).returns("windows")
        platform.stubs(:shell_type).returns("powershell")
      end

      let(:windows_call) { provisioner.wrapped_chef_cmd("cinc_bin", "individual_config.rb") }

      it "includes #reload_ps1_path output" do
        windows_call.include? "[System.Environment]::GetEnvironmentVariable"
      end
    end
  end

  def regexify(str, line = :whole_line)
    r = Regexp.escape(str)
    r = "^\s*#{r}$" if line == :whole_line
    Regexp.new(r)
  end
end
