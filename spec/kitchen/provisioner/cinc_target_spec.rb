#
# Copyright (C) 2024, Progress Software
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
require "kitchen/provisioner/cinc_target"
require "fileutils"
require "tmpdir"

describe Kitchen::Provisioner::CincTarget do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(os_type: nil) }
  let(:suite)           { stub(name: "fries") }
  let(:transport)       { stub(class: Kitchen::Transport::Base) }

  let(:config) do
    { test_base_path: "/b", kitchen_root: "/r" }
  end

  let(:instance) do
    stub(
      name: "coolbeans",
      logger: logger,
      suite: suite,
      platform: platform,
      transport: transport
    )
  end

  let(:provisioner) do
    Kitchen::Provisioner::CincTarget.new(config).finalize_config!(instance)
  end

  describe "check_local_cinc_client" do
    it "raises CincClientNotFound when cinc-client is not found" do
      provisioner.stubs(:`).raises(Errno::ENOENT.new("cinc-client"))

      _ { provisioner.check_local_cinc_client }.must_raise Kitchen::Provisioner::CincTarget::CincClientNotFound
    end

    it "raises CincVersionTooLow when cinc-client version is too low" do
      provisioner.stubs(:`).returns("Cinc Client: 18.0.0\n")

      _ { provisioner.check_local_cinc_client }.must_raise Kitchen::Provisioner::CincTarget::CincVersionTooLow
    end

    it "does not raise when cinc-client version meets minimum" do
      provisioner.stubs(:`).returns("Cinc Client: 19.0.0\n")

      provisioner.check_local_cinc_client
    end

    it "does not raise when cinc-client version exceeds minimum" do
      provisioner.stubs(:`).returns("Cinc Client: 20.1.0\n")

      provisioner.check_local_cinc_client
    end

    it "tolerates a version banner without a colon" do
      provisioner.stubs(:`).returns("Cinc Client 19.1.31\n")

      provisioner.check_local_cinc_client
    end

    it "raises CincClientNotFound when the version cannot be parsed" do
      provisioner.stubs(:`).returns("cinc-client: command not usable\n")

      _ { provisioner.check_local_cinc_client }
        .must_raise Kitchen::Provisioner::CincTarget::CincClientNotFound
    end

    it "raises CincClientNotFound when nothing is printed" do
      provisioner.stubs(:`).returns("")

      _ { provisioner.check_local_cinc_client }
        .must_raise Kitchen::Provisioner::CincTarget::CincClientNotFound
    end

    it "reports the unparsable output so the failure is diagnosable" do
      provisioner.stubs(:`).returns("cinc-client: command not usable\n")

      begin
        provisioner.check_local_cinc_client
      rescue Kitchen::Provisioner::CincTarget::CincClientNotFound
        # expected
      end

      _(logged_output.string).must_include "cinc-client: command not usable"
    end
  end

  describe "#check_transport" do
    it "raises RequireTrainTransport when the connection has no train_uri" do
      _ { provisioner.check_transport(stub) }
        .must_raise Kitchen::Provisioner::CincTarget::RequireTrainTransport
    end

    it "accepts a connection that responds to train_uri" do
      provisioner.check_transport(stub(train_uri: "ssh://host"))
    end
  end

  describe "#chef_args" do
    let(:kitchen_root) { Dir.mktmpdir }
    let(:driver)       { stub(config: { kitchen_root: kitchen_root }, cache_directory: nil) }
    let(:connection)   { stub(train_uri: "ssh://host", credentials_file: "[host]\nkey = value\n") }

    let(:instance) do
      stub(
        name: "coolbeans",
        logger: logger,
        suite: suite,
        platform: platform,
        transport: transport,
        driver: driver,
        remote_exec: connection
      )
    end

    before do
      provisioner.stubs(:check_local_cinc_client)
      config[:root_path] = "/tmp/kitchen"
    end

    after { FileUtils.remove_entry(kitchen_root) }

    it "quotes the target and credentials arguments" do
      args = provisioner.chef_args("client.rb")

      _(args).must_include %{--target "coolbeans"}
      _(args).must_include %{--credentials "#{File.join(kitchen_root, ".kitchen", "coolbeans.ini")}"}
    end

    it "writes the credentials file even when .kitchen does not exist yet" do
      provisioner.chef_args("client.rb")

      credentials = File.join(kitchen_root, ".kitchen", "coolbeans.ini")
      _(File.exist?(credentials)).must_equal true
      _(File.read(credentials)).must_equal "[host]\nkey = value\n"
    end

    it "keeps the credentials file readable only by its owner" do
      skip "POSIX file modes only" if running_tests_on_windows?

      provisioner.chef_args("client.rb")

      credentials = File.join(kitchen_root, ".kitchen", "coolbeans.ini")
      _(padded_octal_string(File.stat(credentials).mode & 0777)).must_equal "0600"
    end
  end

  describe "#call" do
    let(:remote_connection) { stub(upload: nil, download: nil) }
    let(:transport)         { stub(class: Kitchen::Transport::Base, connection: remote_connection) }

    let(:instance) do
      stub(
        name: "coolbeans",
        logger: logger,
        suite: suite,
        platform: platform,
        transport: transport,
        to_str: "coolbeans"
      )
    end

    before do
      provisioner.stubs(:create_sandbox)
      provisioner.stubs(:cleanup_sandbox)
    end

    it "streams the command output into the logger" do
      provisioner.stubs(:run_command).returns("echo hello-from-cinc")

      provisioner.call({})

      _(logged_output.string).must_include "hello-from-cinc"
    end

    it "raises ActionFailed when cinc-client exits non-zero" do
      provisioner.stubs(:run_command).returns("exit 3")

      err = _ { provisioner.call({}) }.must_raise Kitchen::ActionFailed
      _(err.message).must_include "3"
    end

    it "does not raise when cinc-client exits zero" do
      provisioner.stubs(:run_command).returns("exit 0")

      provisioner.call({})
    end

    it "always cleans up the sandbox" do
      provisioner.stubs(:run_command).returns("exit 3")
      provisioner.unstub(:cleanup_sandbox)
      provisioner.expects(:cleanup_sandbox)

      _ { provisioner.call({}) }.must_raise Kitchen::ActionFailed
    end
  end
end
