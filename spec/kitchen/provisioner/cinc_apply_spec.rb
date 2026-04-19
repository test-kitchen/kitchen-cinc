#
# Copyright (C) 2014, Fletcher Nichol
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
require "kitchen/provisioner/cinc_apply"

describe Kitchen::Provisioner::CincApply do
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
    Kitchen::Provisioner::CincApply.new(config).finalize_config!(instance)
  end

  it "provisioner api_version is 2" do
    _(provisioner.diagnose_plugin[:api_version]).must_equal 2
  end

  it "plugin_version is set to Kitchen::VERSION" do
    _(provisioner.diagnose_plugin[:version]).must_equal Kitchen::VERSION
  end

  describe "default config" do
    describe "for unix operating systems" do
      before { platform.stubs(:os_type).returns("unix") }

      it "sets :chef_apply_path to a path using :chef_omnibus_root" do
        config[:chef_omnibus_root] = "/nice/place"

        _(provisioner[:chef_apply_path]).must_equal "/nice/place/bin/cinc-apply"
      end

      it "sets :ruby_bindir to use an Omnibus Ruby" do
        config[:chef_omnibus_root] = "/nice"

        _(provisioner[:ruby_bindir]).must_equal "/nice/embedded/bin"
      end
    end

    describe "for windows operating systems" do
      before { platform.stubs(:os_type).returns("windows") }

      it "sets :chef_apply_path to a path using :chef_omnibus_root" do
        config[:chef_omnibus_root] = '$env:systemdrive\\nice\\place'

        _(provisioner[:chef_apply_path]).must_equal '$env:systemdrive\\nice\\place\\bin\\cinc-apply.bat'
      end

      it "sets :ruby_bindir to use an Omnibus Ruby" do
        config[:chef_omnibus_root] = 'c:\\nice'

        _(provisioner[:ruby_bindir]).must_equal 'c:\\nice\\embedded\\bin'
      end
    end
  end

  describe "#run_command" do
    before do
      config[:run_list] = %w{appry_recipe1 appry_recipe2}
    end

    let(:cmd) { provisioner.run_command }

    describe "for bourne shells" do
      before { platform.stubs(:shell_type).returns("bourne") }

      it "uses sudo for cinc-apply when configured" do
        config[:chef_omnibus_root] = "/c"
        config[:sudo] = true

        _(cmd).must_match regexify("sudo -E /c/bin/cinc-apply ", :partial_line)
      end

      it "does not use sudo for cinc-apply when configured" do
        config[:chef_omnibus_root] = "/c"
        config[:sudo] = false

        _(cmd).must_match regexify("/c/bin/cinc-apply ", :partial_line)
        _(cmd).wont_match regexify("sudo -E /c/bin/cinc-apply ", :partial_line)
      end

      it "sets log level flag on cinc-apply to auto by default" do
        _(cmd).must_match regexify(" --log_level auto", :partial_line)
      end

      it "sets no color flag on cinc-apply" do
        _(cmd).must_match regexify(" --no-color", :partial_line)
      end

      it "prefixes the whole command with the command_prefix if set" do
        config[:command_prefix] = "my_prefix"

        _(cmd).must_match(/\Amy_prefix /)
      end

      it "does not prefix the command if command_prefix is not set" do
        config[:command_prefix] = nil

        _(cmd).wont_match(/\Amy_prefix /)
      end
    end

    describe "for powershell shells on windows os types" do
      before do
        platform.stubs(:shell_type).returns("powershell")
        platform.stubs(:os_type).returns("windows")
      end

      it "calls the cinc-apply command from :chef_apply_path" do
        config[:chef_apply_path] = '\\r\\cinc-apply.bat'

        _(cmd).must_match regexify('& \\r\\cinc-apply.bat ', :partial_line)
      end
    end
  end

  def regexify(str, line = :whole_line)
    r = Regexp.escape(str)
    r = "^\s*#{r}$" if line == :whole_line
    Regexp.new(r)
  end
end
