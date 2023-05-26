source "https://rubygems.org"

gemspec

gem "logger", "< 1.6" # 1.6 causes errors with mixlib-log < 3.1.1

group :test do
  gem "rake"
  gem "rspec", "~> 3.8"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle"
  gem "chefstyle"
  gem "test-kitchen"
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

source "https://artifactory-internal.ps.chef.co/artifactory/api/gems/omnibus-gems-local/" do
  gem "chef-licensing"
end