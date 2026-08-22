source "https://rubygems.org"

gemspec development_group: :test
gem "mixlib-install", ">= 3.14", source: "https://rubygems.cinc.sh"
gem "chef-cli", ">= 5.3.1", source: "https://rubygems.cinc.sh"
gem "chef", ">= 19.0", source: "https://rubygems.cinc.sh"
gem "chef-bin", ">= 19.0", source: "https://rubygems.cinc.sh"
gem "chef-utils", source: "https://rubygems.cinc.sh"
gem "chef-zero", source: "https://rubygems.cinc.sh"

# Transitive deps of cinc-branded gems that aren't on rubygems.cinc.sh
gem "unf_ext", ">= 0.0.8.2"

group :test do
  gem "rake"
  gem "fakefs"
  gem "minitest"
  gem "mocha"
  gem "test-kitchen"
end

group :integration do
  gem "kitchen-dokken"
  gem "kitchen-vagrant"
  gem "kitchen-inspec"
end

group :linting do
  gem "cookstyle"
end
