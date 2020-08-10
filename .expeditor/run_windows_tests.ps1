$ErrorActionPreference="stop"

Write-Host "--- bundle install"

bundle config --local path vendor/bundle
bundle config --local set without 'docs development profile'
bundle install --jobs=7 --retry=3

Write-Host "+++ bundle exec task"
bundle exec $args
if ($LASTEXITCODE -ne 0) { throw "$args failed" }
