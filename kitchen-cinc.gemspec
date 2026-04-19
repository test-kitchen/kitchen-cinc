lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kitchen/provisioner/cinc_version"
require "English"

Gem::Specification.new do |gem|
  gem.name          = "kitchen-cinc"
  gem.version       = Kitchen::Provisioner::CINC_VERSION
  gem.license       = "Apache-2.0"
  gem.authors       = ["Cinc Project"]
  gem.email         = ["maintainers@cinc.sh"]
  gem.description   = "Test Kitchen provisioner for Cinc Client (community distribution of Chef)"
  gem.summary       = gem.description
  gem.homepage      = "https://cinc.sh/"

  gem.metadata = {
    "homepage_uri" => "https://cinc.sh/",
    "source_code_uri" => "https://gitlab.com/cinc-project/kitchen-cinc",
    "changelog_uri" => "https://gitlab.com/cinc-project/kitchen-cinc/-/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://gitlab.com/cinc-project/kitchen-cinc/-/issues",
  }

  # The gemfile and gemspec are necessary for appbundler in Cinc Workstation
  gem.files         = %w{LICENSE kitchen-cinc.gemspec Gemfile Rakefile} + Dir.glob("{lib,support}/**/*")
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 3.1"

  gem.add_dependency "test-kitchen",       ">= 4.0"
  gem.add_dependency "mixlib-install",     ">= 3.14"
  gem.add_dependency "mixlib-shellout",    ">= 1.2", "< 4.0"
end
