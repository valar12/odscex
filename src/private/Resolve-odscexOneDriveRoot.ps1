function Resolve-odscexOneDriveRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $User
    )

    try {
        return Invoke-odscexApiRequest -Resource "users/${User}/drive/root" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
    } catch {
        $Message = $_.Exception.Message
        $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
        if ($StatusCode -eq 404) {
            Write-Error "Unable to access OneDrive for '$User'. Microsoft Graph returned 404 for users/${User}/drive/root. Verify the user identifier is correct, the user's OneDrive is provisioned, and the account has a SharePoint/OneDrive license. If the UPN recently changed, try -UserObjectId instead of -UserPrincipalName." -ErrorAction Stop
        }

        if ($StatusCode -eq 403) {
            Write-Error "Unable to access OneDrive for '$User'. Microsoft Graph returned 403 for users/${User}/drive/root. Verify the signed-in application or user has Files.ReadWrite.All and User.Read.All or equivalent application permissions, and that admin consent has been granted." -ErrorAction Stop
        }

        Write-Error "Unable to access OneDrive for '$User' before creating the shortcut. $Message" -ErrorAction Stop
    }
}
