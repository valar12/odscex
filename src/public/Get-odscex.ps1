function Get-odscex {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName')]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $RelativePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId')]
        [string] $ShortcutName,

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

        $ShortcutRequest = @{
            Resource = Join-odscexDrivePathResource -User $User -RelativePath $RelativePath -Name $ShortcutName
            Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
        }

        $ShortcutResponse = Invoke-odscexApiRequest @ShortcutRequest

        if (!($ShortcutResponse)) {
            Write-Verbose "Request: $($ShortcutRequest.Resource)"
            Write-Error "Error getting OneDrive shortcut '$($ShortcutName)' for ${User}." -ErrorAction Stop
        }

        return $ShortcutResponse
    }
}
