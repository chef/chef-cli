source "https://rubygems.org"

gemspec

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :test do
  gem "rake"
  gem "rspec", "~> 3.8"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle", "6.14.7" # this forces dependabot PRs to open which triggers cookstyle CI on the chef generate command
  gem "chefstyle", "1.2.0"
  gem "test-kitchen", "> 2.5"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
    gem "chef", "~> 15"
  end
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer", "~> 0.4.0"
  gem "rb-readline"
end
