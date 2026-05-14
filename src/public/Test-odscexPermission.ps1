function Test-odscexPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [string] $UserObjectId
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
            Invoke-odscexApiRequest -Resource "users/${User}/drive" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) | Out-Null
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

    return $Checks.ToArray()
}
