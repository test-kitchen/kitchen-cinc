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
require "kitchen/provisioner/cinc_zero"

describe Kitchen::Provisioner::CincZero do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(os_type: nil) }
  let(:suite)           { stub(name: "fries") }

  let(:config) do
    { test_base_path: "/b", kitchen_root: "/r" }
  end

  let(:instance) do
    stub(
      name: "coolbeans",
      logger: logger,
      suite: suite,
      platform: platform
    )
  end

  let(:provisioner) do
    Kitchen::Provisioner::CincZero.new(config).finalize_config!(instance)
  end

  it "inherits from CincInfra" do
    _(Kitchen::Provisioner::CincZero.superclass).must_equal Kitchen::Provisioner::CincInfra
  end

  it "provisioner api_version is 2" do
    _(provisioner.diagnose_plugin[:api_version]).must_equal 2
  end

  it "plugin_version is set to Kitchen::VERSION" do
    _(provisioner.diagnose_plugin[:version]).must_equal Kitchen::VERSION
  end
end
