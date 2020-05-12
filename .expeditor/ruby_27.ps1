$ErrorActionPreference="stop"

Write-Host "--- Installing Ruby 2.7"
(New-Object System.Net.WebClient).DownloadFile('https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.1-1/rubyinstaller-devkit-2.7.1-1-x64.exe', 'c:\rubyinstaller-devkit-2.7.1-1-x64.exe')
Start-Process c:/rubyinstaller-devkit-2.7.1-1-x64.exe -ArgumentList '/verysilent /dir=C:\ruby27' -Wait
Set-Item -Path Env:Path -Value ("C:\ruby27\bin;" + $Env:Path)

Write-Host "--- Executing tests"
bundle config --local path vendor/bundle
bundle config --local set without 'docs development'
bundle install --jobs=7 --retry=3
bundle exec rspec
if ($LASTEXITCODE -ne 0) { throw "rspec failed" }
