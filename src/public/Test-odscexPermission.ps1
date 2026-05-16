function Test-odscexPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [string] $UserObjectId,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibraryId,

        [Parameter(Mandatory = $false)]
        [string] $FolderPath,

        [Parameter(Mandatory = $false)]
        [switch] $AllowAmbiguousLibraryMatch
    )

    $Checks = New-Object System.Collections.Generic.List[object]

    try {
        Invoke-odscexApiRequest -Resource 'organization' -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) | Out-Null
        $Checks.Add([pscustomobject]@{ Check = 'GraphConnection'; Status = 'Passed'; Message = 'Token can call Microsoft Graph.' }) | Out-Null
    } catch {
        $Checks.Add([pscustomobject]@{ Check = 'GraphConnection'; Status = 'Failed'; Message = $_.Exception.Message }) | Out-Null
    }

    if ($UserPrincipalName -or $UserObjectId) {
        $User = if ($UserObjectId) { $UserObjectId } else { $UserPrincipalName }
        try {
            Resolve-odscexOneDriveRoot -User $User | Out-Null
            $Checks.Add([pscustomobject]@{ Check = 'UserDriveAccess'; Status = 'Passed'; Message = "Can read OneDrive drive for '$User'." }) | Out-Null
        } catch {
            $Checks.Add([pscustomobject]@{ Check = 'UserDriveAccess'; Status = 'Failed'; Message = $_.Exception.Message }) | Out-Null
        }
    }

    if ($Uri) {
        try {
            $SiteUri = [uri]$Uri
            Invoke-odscexApiRequest -Resource "sites/$($SiteUri.Authority):$($SiteUri.AbsolutePath.TrimEnd('/'))" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) | Out-Null
            $Checks.Add([pscustomobject]@{ Check = 'SiteAccess'; Status = 'Passed'; Message = "Can read SharePoint site '$Uri'." }) | Out-Null
        } catch {
            $Checks.Add([pscustomobject]@{ Check = 'SiteAccess'; Status = 'Failed'; Message = $_.Exception.Message }) | Out-Null
        }
    }

    if ($Uri -and ($DocumentLibrary -or $DocumentLibraryId)) {
        try {
            $TargetParameters = @{
                Uri = $Uri
            }
            if ($DocumentLibrary) { $TargetParameters.DocumentLibrary = $DocumentLibrary }
            if ($DocumentLibraryId) { $TargetParameters.DocumentLibraryId = $DocumentLibraryId }
            if ($FolderPath) { $TargetParameters.FolderPath = $FolderPath }
            if ($AllowAmbiguousLibraryMatch) { $TargetParameters.AllowAmbiguousLibraryMatch = $true }
            Resolve-odscexShortcutTarget @TargetParameters | Out-Null
            $TargetName = if ($DocumentLibrary) { $DocumentLibrary } else { $DocumentLibraryId }
            $Checks.Add([pscustomobject]@{ Check = 'ShortcutTargetAccess'; Status = 'Passed'; Message = "Can resolve shortcut target '$TargetName'." }) | Out-Null
        } catch {
            $Checks.Add([pscustomobject]@{ Check = 'ShortcutTargetAccess'; Status = 'Failed'; Message = $_.Exception.Message }) | Out-Null
        }
    } elseif (($DocumentLibrary -or $DocumentLibraryId -or $FolderPath) -and (-not $Uri)) {
        $Checks.Add([pscustomobject]@{ Check = 'ShortcutTargetAccess'; Status = 'Failed'; Message = 'Specify -Uri with -DocumentLibrary, -DocumentLibraryId, or -FolderPath to validate a shortcut target.' }) | Out-Null
    }

    return $Checks.ToArray()
}
