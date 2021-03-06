Function Get-Atom {
    <#
        .SYNOPSIS
            Returns the latest Atom version number and download.

        .DESCRIPTION
            Returns the latest Atom version number and download.

        .NOTES
            Author: Aaron Parker
            Twitter: @stealthpuppy
        
        .LINK
            https://github.com/aaronparker/Evergreen

        .EXAMPLE
            Get-Atom

            Description:
            Returns the latest Atom version number and download for each platform.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    Param()

    # Get application resource strings from its manifest
    $res = Get-FunctionResource -AppName ("$($MyInvocation.MyCommand)".Split("-"))[1]
    Write-Verbose -Message $res.Name

    # Get latest version and download latest Atom release via GitHub API
    # Query the Atom repository for releases, keeping the latest stable release
    $iwcParams = @{
        Uri         = $res.Get.Uri
        ContentType = $res.Get.ContentType
        Raw         = $True
    }
    $Content = Invoke-WebContent @iwcParams

    If ($Null -ne $Content) {
        $json = $Content | ConvertFrom-Json
        $releases = $json | Where-Object { $_.prerelease -ne $True }
        $latestRelease = $releases | Select-Object -First 1

        # Build the output object with release details
        ForEach ($release in $latestRelease.assets) {

            If ($release.browser_download_url -match $res.Get.MatchExtensions) {
                Switch -Regex ($release.browser_download_url) {
                    "amd64" { $arch = "AMD64" }
                    "arm64" { $arch = "ARM64" }
                    "arm32" { $arch = "ARM32" }
                    "x86_64" { $arch = "x86_64" }
                    "x64" { $arch = "x64" }
                    "x86" { $arch = "x86" }
                    Default { $arch = "x86" }
                }

                Switch -Regex ($release.browser_download_url) {
                    "rpm" { $platform = "RHEL" }
                    "win" { $platform = "Windows" }
                    "exe" { $platform = "Windows" }
                    "mac" { $platform = "macOS" }
                    "deb" { $platform = "Debian" }
                    Default { $platform = "Unknown" }
                }

                # Match version number
                $latestRelease.tag_name -match $res.Get.MatchVersion | Out-Null
                $Version = $Matches[0]

                $PSObject = [PSCustomObject] @{
                    Version      = $Version
                    Platform     = $platform
                    Architecture = $arch
                    Date         = (ConvertTo-DateTime -DateTime $release.created_at)
                    Size         = $release.size
                    URI          = $release.browser_download_url
                }
                Write-Output -InputObject $PSObject
            }
        }
    }
}
