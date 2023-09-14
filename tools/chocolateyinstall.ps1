$ErrorActionPreference = 'Stop'

Confirm-Win10

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'VCam.ai'
$predecessorKeys = Get-PredecessorUninstallRegistryKey
if ($null -ne $predecessorKeys) {
  $predecessorKey = $predecessorKeys[0]
  $predecessorName = $($predecessorKey.DisplayName)
  Write-Warning "An installation of $softwareName's predecessor ($predecessorName - v$($predecessorKey.DisplayVersion)) was detected.
    While $softwareName effectively supersedes it, the migration process will require manual reconfiguration.
    Once the migration is complete, consider uninstalling $predecessorName at your earliest convenience."
}

[version] $softwareVersion = '1.0.2308.2506'
$installedVersion = Get-CurrentVersion

if ($installedVersion -eq $softwareVersion -and !$env:ChocolateyForce) {
  Write-Output "$softwareName v$installedVersion is already installed."
  Write-Output 'Skipping download and execution of installer.'
}
else {
  if ($softwareVersion -lt $installedVersion) {
    Write-Output "Current installed version (v$installedVersion) must be uninstalled first..."
    Uninstall-CurrentVersion
  }

  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    fileType       = 'MSI'
    url64bit       = 'https://downloads.vcam.ai/1.0.2308.2506/VCam.ai_1.0.2308.2506.msi'
    softwareName   = $softwareName
    checksum64     = '76f132cad7c678fe1482f1ed8e2068fbaf351aacb6f1ff898c6feb6067fd36fd'
    checksumType64 = 'sha256'
    silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
