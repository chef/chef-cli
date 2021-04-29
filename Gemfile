source "https://rubygems.org"

gemspec

group :test do
  gem "rake"
  gem "rspec", "~> 3.8"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle", "=7.7.2" # this forces dependabot PRs to open which triggers cookstyle CI on the chef generate command
  gem "chefstyle", "=1.6.2"
  gem "test-kitchen", ">= 2.11.1"
end

group :profile do
  gem "stackprof"
  gem "stackprof-webnav"
  gem "memory_profiler"
end
