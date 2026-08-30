#
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

require_relative "../../../spec_helper"
require "kitchen/provisioner/cinc/berkshelf"

describe Kitchen::Provisioner::Cinc::Berkshelf do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }

  describe ".load!" do
    it "raises a UserError when the berkshelf gem cannot be loaded" do
      Kitchen::Provisioner::Cinc::Berkshelf.stubs(:require)
        .with("berkshelf")
        .raises(LoadError, "cannot load such file -- berkshelf")

      err = _ { Kitchen::Provisioner::Cinc::Berkshelf.load!(logger: logger) }
        .must_raise Kitchen::UserError
      _(err.message).must_include "Could not load or activate Berkshelf"
    end

    it "tells the user how to install berkshelf when it is missing" do
      Kitchen::Provisioner::Cinc::Berkshelf.stubs(:require)
        .with("berkshelf")
        .raises(LoadError, "cannot load such file -- berkshelf")

      begin
        Kitchen::Provisioner::Cinc::Berkshelf.load!(logger: logger)
      rescue Kitchen::UserError
        # expected
      end

      _(logged_output.string).must_include "gem install berkshelf"
    end

    it "logs on debug when the library loads for the first time" do
      stub_berkshelf_constant("8.0.0") do
        Kitchen::Provisioner::Cinc::Berkshelf.stubs(:require)
          .with("berkshelf")
          .returns(true)

        Kitchen::Provisioner::Cinc::Berkshelf.load!(logger: logger)
      end

      _(logged_output.string).must_include "Berkshelf 8.0.0 library loaded"
    end

    it "logs on debug when the library was already loaded" do
      stub_berkshelf_constant("8.0.0") do
        Kitchen::Provisioner::Cinc::Berkshelf.stubs(:require)
          .with("berkshelf")
          .returns(false)

        Kitchen::Provisioner::Cinc::Berkshelf.load!(logger: logger)
      end

      _(logged_output.string).must_include "Berkshelf 8.0.0 previously loaded"
    end
  end

  # Defines a minimal top-level ::Berkshelf for the duration of the block, so
  # the resolver can be exercised without the real (heavy) gem installed.
  def stub_berkshelf_constant(version)
    already_defined = Object.const_defined?(:Berkshelf)
    skip "the real Berkshelf gem is loaded" if already_defined

    Object.const_set(:Berkshelf, Module.new { const_set(:VERSION, version) })
    yield
  ensure
    Object.send(:remove_const, :Berkshelf) unless already_defined
  end
end
