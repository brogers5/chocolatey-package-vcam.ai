Import-Module au

$userAgent = "Update checker of Chocolatey Community Package 'vcam.ai'"

function Get-RedirectedUri([uri] $CanonicalUri) {
    $response = Invoke-WebRequest -Uri $CanonicalUri -UserAgent $userAgent -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction Ignore

    return $response.Headers['Location']
}

function global:au_BeforeUpdate($Package) {
    $Latest.ReleaseNotes = Get-RedirectedUri -CanonicalUri 'https://xspl.it/vcamai/relnotes'
    $packageReleaseNotes = $Package.NuspecXml.package.metadata.releaseNotes

    #SplitMediaLabs sometimes reuses URLs or doesn't bother to publish new release notes.
    #For package release note purposes, note when this happens.
    if ($packageReleaseNotes -eq $Latest.ReleaseNotes) {
        Write-Warning 'releaseNotes URL is identical'
        Write-Warning 'URL may have been reused, or no URL may be available'
    }

    #Archive this version for future development, since the vendor does not guarantee perpetual availability
    $filePath = ".\VCam.ai_$($Latest.Version).msi"
    Invoke-WebRequest -Uri $Latest.Url64 -OutFile $filePath
    $Latest.Checksum64 = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash.ToLower()

    Set-DescriptionFromReadme -Package $Package -ReadmePath '.\DESCRIPTION.md'
}

function global:au_SearchReplace {
    @{
        'tools\chocolateyInstall.ps1'   = @{
            '(^\[version\] \$softwareVersion\s*=\s*)''.*''' = "`$1'$($Latest.SoftwareVersion)'"
            '(^[$]?\s*url64bit\s*=\s*)(''.*'')'             = "`$1'$($Latest.Url64)'"
            '(^[$]?\s*checksum64\s*=\s*)(''.*'')'           = "`$1'$($Latest.Checksum64)'"
        }
        "$($Latest.PackageName).nuspec" = @{
            '(<packageSourceUrl>)[^<]*(</packageSourceUrl>)' = "`$1https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)`$2"
            '(\<releaseNotes\>).*?(\</releaseNotes\>)'       = "`${1}$($Latest.ReleaseNotes)`$2"
            '(<copyright>)[^<]*(</copyright>)'               = "`$1© $(Get-Date -Format yyyy) SplitmediaLabs, Ltd. All Rights Reserved.`$2"
        }
    }
}

function global:au_GetLatest {
    $canonicalDownloadUri = Get-RedirectedUri -CanonicalUri 'https://xspl.it/vcamai/download'
    $version = Get-Version -Version $canonicalDownloadUri

    # Use MSI package instead, as the copy packaged in EXE package differs slightly and supports less installer properties
    $downloadUri = $canonicalDownloadUri.TrimEnd('.exe') + '.msi'

    return @{
        SoftwareVersion = $version
        Url64           = $downloadUri
        Version         = $version #This may change if building a package fix version
    }
}

Update-Package -ChecksumFor None -NoReadme
