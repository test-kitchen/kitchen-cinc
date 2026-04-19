#
# Copyright (C) 2024, Progress Software
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

require_relative "../../spec_helper"

require "kitchen"
require "kitchen/provisioner/cinc_target"

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
  end
end
