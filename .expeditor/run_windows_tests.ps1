$ErrorActionPreference="stop"
Write-Host "Manually clearing the chef-test-kitchen-enterprise cache"
Remove-Item -Recurse -Force "C:/workdir/vendor/bundle/ruby/3.1.0/cache/bundler/git/chef-test-kitchen-enterprise-dba8545c33365a2bffe55f9cb935af5b46709af2"
Write-Host "Cleaned the previous cache"

Write-Host "--- bundle install"

bundle config --local path vendor/bundle
bundle config set --local without docs development profile
bundle install --jobs=7 --retry=3 

Write-Host "+++ bundle exec task"
bundle exec $args
if ($LASTEXITCODE -ne 0) { throw "$args failed" }
