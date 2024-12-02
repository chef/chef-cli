param (
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows/1.0.0/20190812103929")
)

# ensure Pester is available for test use
if (-Not (Get-Module -ListAvailable -Name Pester)){
    hab pkg install core/pester
    Import-Module "$(hab pkg path core/pester)\module\pester.psd1"
}

Write-Host "--- :fire: Smokish Pestering"
# Pester the Package
$version=hab pkg exec "${pkg_ident}" chef-cli -v
$actual_version=[Regex]::Match($version,"([0-9]+.[0-9]+.[0-9]+)").Value
$package_version=$PackageIdentifier.split("/",4)[2]
if ($package_version -eq $actual_version)
{
    Write "Chef-cli working fine"
}
else {
    Write-Error "chef-cli version not met expected $package_version actual version $actual_version "
}