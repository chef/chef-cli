source "https://rubygems.org"

gemspec

group :test do
  gem "rake"
  gem "rspec", "~> 3.8"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle", "=7.32.2" # this forces dependabot PRs to open which triggers cookstyle CI on the chef generate command
  gem "chefstyle", "=2.2.3"
  gem "test-kitchen", ">= 2.11.1"

  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
    gem "chef", "~> 15"
    gem "chef-utils", "=16.6.14"
  end
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7")
    gem "ohai", "~> 16"
  end

  gem "simplecov", require: false
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"
end

group :profile do
  gem "stackprof"
  gem "stackprof-webnav"
  gem "memory_profiler"
end
