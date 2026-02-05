source "https://rubygems.org"

gemspec

gem "logger", "< 1.6" # 1.6 causes errors with mixlib-log < 3.1.1
gem "chefspec"

group :test do
  gem "rake"
  gem "rspec", "=3.12.0"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle", ">= 7.32"
  gem "faraday_middleware"
  gem "chef-test-kitchen-enterprise", git: "https://github.com/chef/chef-test-kitchen-enterprise", branch: "main"
  # kitchen-omnibus-chef requires test-kitchen >= 4.0, so we need to explicitly add the test-kitchen alias gem
  # test-kitchen is an alias gem provided by chef-test-kitchen-enterprise via test-kitchen.gemspec
  gem "test-kitchen", git: "https://github.com/chef/chef-test-kitchen-enterprise", branch: "main", glob: "test-kitchen.gemspec"
  # TODO: Replace kitchen-omnibus-chef with kitchen-chef-enterprise once private repo access is available for public runners
  # kitchen-omnibus-chef is deprecated and won't receive updates, but provides chef-zero provisioner functionality
  # gem "kitchen-chef-enterprise", git: "https://github.com/chef/kitchen-chef-enterprise", branch: "main"
  gem "kitchen-omnibus-chef", "~> 1.1"
  gem "simplecov", require: false
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"
  gem "appbundler"
end

group :profile do
  unless RUBY_PLATFORM.match?(/mswin|mingw|windows/)
    gem "stackprof"
    gem "stackprof-webnav"
    gem "memory_profiler"
  end
end