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

require_relative "../../spec_helper"

require "kitchen"
require "kitchen/provisioner/chef_alias_loader"

describe Kitchen::Provisioner::ChefAliasLoader do
  let(:loader) { Kitchen::Provisioner::ChefAliasLoader }

  describe ".enterprise_spec" do
    it "returns nil when kitchen-chef-enterprise is not installed" do
      Gem::Specification.expects(:find_by_name)
        .with("kitchen-chef-enterprise")
        .raises(Gem::LoadError, "not found")

      _(loader.enterprise_spec).must_be_nil
    end

    it "returns the spec when kitchen-chef-enterprise is installed" do
      spec = stub(gem_dir: "/gems/kitchen-chef-enterprise-1.0.0")
      Gem::Specification.expects(:find_by_name)
        .with("kitchen-chef-enterprise")
        .returns(spec)

      _(loader.enterprise_spec).must_equal spec
    end
  end

  describe ".defer_to_enterprise" do
    it "returns false when kitchen-chef-enterprise is not installed" do
      loader.stubs(:enterprise_spec).returns(nil)
      loader.expects(:require).never

      _(loader.defer_to_enterprise(:ChefInfra)).must_equal false
    end

    it "returns false when the gem does not ship that provisioner" do
      loader.stubs(:enterprise_spec).returns(stub(gem_dir: "/gems/kce"))
      File.stubs(:exist?)
        .with("/gems/kce/lib/kitchen/provisioner/chef_infra.rb")
        .returns(false)
      loader.expects(:require).never

      _(loader.defer_to_enterprise(:ChefInfra)).must_equal false
    end

    it "loads the enterprise implementation from its absolute path" do
      path = "/gems/kce/lib/kitchen/provisioner/chef_infra.rb"
      loader.stubs(:enterprise_spec).returns(stub(gem_dir: "/gems/kce"))
      File.stubs(:exist?).with(path).returns(true)
      loader.expects(:require).with(path).returns(true)
      Kitchen::Provisioner.stubs(:const_defined?).with(:ChefInfra, false).returns(true)

      _(loader.defer_to_enterprise(:ChefInfra)).must_equal true
    end

    it "snake_cases multi-word constant names when building the path" do
      path = "/gems/kce/lib/kitchen/provisioner/chef_target.rb"
      loader.stubs(:enterprise_spec).returns(stub(gem_dir: "/gems/kce"))
      File.expects(:exist?).with(path).returns(false)

      _(loader.defer_to_enterprise(:ChefTarget)).must_equal false
    end

    it "returns false when the required file did not define the constant" do
      path = "/gems/kce/lib/kitchen/provisioner/chef_solo.rb"
      loader.stubs(:enterprise_spec).returns(stub(gem_dir: "/gems/kce"))
      File.stubs(:exist?).with(path).returns(true)
      loader.stubs(:require).with(path).returns(true)
      Kitchen::Provisioner.stubs(:const_defined?).with(:ChefSolo, false).returns(false)

      _(loader.defer_to_enterprise(:ChefSolo)).must_equal false
    end
  end
end
