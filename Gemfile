source "https://rubygems.org"

gemspec

gem "logger", "< 1.6" # 1.6 causes errors with mixlib-log < 3.1.1
gem "chefspec"

group :test do
  gem "rake"
  gem "rspec", "=3.12.0"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle"
  gem "chefstyle"
  gem "faraday_middleware"
  gem "chef-test-kitchen-enterprise", git: "https://github.com/chef/chef-test-kitchen-enterprise", branch: "main"
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