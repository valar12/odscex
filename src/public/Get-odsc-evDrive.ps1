function Get-odsc-evDrive {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName', ValueFromPipelineByPropertyName = $true)]
        [Alias('Mail')]
        [string] $UserPrincipalName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId', ValueFromPipelineByPropertyName = $true)]
        [Alias('Id', 'UserId')]
        [string] $UserObjectId
    )

    process {
        $User = switch ($PsCmdlet.ParameterSetName) {
            'UserPrincipalName' { $UserPrincipalName }
            'UserObjectId' { $UserObjectId }
        }

        $DriveResponse = Invoke-odsc-evApiRequest -Resource "users/${User}/drive" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)

        if (!($DriveResponse)) {
            Write-Error "Error getting OneDrive drive for ${User}." -ErrorAction Stop
        }

        return $DriveResponse
    }
}
