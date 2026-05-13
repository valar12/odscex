function Remove-odsc {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName', SupportsShouldProcess)]
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
        [string] $UserObjectId,

        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )

    process {
        $User = switch ($PsCmdlet.ParameterSetName) {
            'UserPrincipalName' { $UserPrincipalName }
            'UserObjectId' { $UserObjectId }
        }

        $ShortcutResource = Join-odscDrivePathResource -User $User -RelativePath $RelativePath -Name $ShortcutName
        $ShortcutResponse = Invoke-odscApiRequest -Resource $ShortcutResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)

        if (-not $ShortcutResponse.remoteItem) {
            Write-Verbose "Request: $ShortcutResource"
            Write-Error "Error removing OneDrive shortcut '$($ShortcutName)' for ${User}. Resource type is not remoteItem." -ErrorAction Stop
        }

        if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Removing shortcut '$($ShortcutName)'")) {
            $RemoveResponse = Invoke-odscApiRequest -Resource $ShortcutResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete)

            if ($PassThru) {
                return Write-odscResult -User $User -ShortcutName $ShortcutName -Action 'Remove' -Status 'Removed' -Response $ShortcutResponse
            }

            return $RemoveResponse
        }
    }
}
