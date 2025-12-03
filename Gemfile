source "https://rubygems.org"

gemspec

gem "logger", "< 1.6" # 1.6 causes errors with mixlib-log < 3.1.1

# Pin psych < 5.2 to avoid build issues on Windows Ruby 3.3 where libyaml headers are unavailable
# Ruby 3.3 ships with psych 5.1.2, Ruby 3.4+ will handle 5.2+ correctly
gem "psych", "< 5.2" if RUBY_VERSION.start_with?("3.3")

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
  gem "pry-byebug", platforms: :ruby  # byebug doesn't work on Windows
  gem "rb-readline"
end

group :profile do
  gem "stackprof"
  gem "stackprof-webnav"
  gem "memory_profiler"
end
