function Set-odscexShortcutState {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId')]
        [string] $Uri,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $DocumentLibraryId,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $FolderPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $RelativePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'UserPrincipalName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UserObjectId')]
        [string] $ShortcutName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName', ValueFromPipelineByPropertyName = $true)]
        [Alias('Mail')]
        [string] $UserPrincipalName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserObjectId', ValueFromPipelineByPropertyName = $true)]
        [Alias('Id', 'UserId')]
        [string] $UserObjectId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [string] $State = 'Present',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Skip', 'Replace', 'Rename', 'Error')]
        [string] $ConflictAction = 'Skip',

        [Parameter(Mandatory = $false)]
        [switch] $AllowAmbiguousLibraryMatch,

        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )

    process {
        if (-not $DocumentLibrary -and -not $DocumentLibraryId) {
            Write-Error 'Specify -DocumentLibrary or -DocumentLibraryId.' -ErrorAction Stop
        }

        $User = switch ($PsCmdlet.ParameterSetName) {
            'UserPrincipalName' { $UserPrincipalName }
            'UserObjectId' { $UserObjectId }
        }

        $Target = Resolve-odscexShortcutTarget -Uri $Uri -DocumentLibrary $DocumentLibrary -DocumentLibraryId $DocumentLibraryId -FolderPath $FolderPath -AllowAmbiguousLibraryMatch:$AllowAmbiguousLibraryMatch
        if (-not $ShortcutName) {
            $ShortcutName = $Target.DefaultShortcutName
        }

        $ShortcutResource = Join-odscexDrivePathResource -User $User -RelativePath $RelativePath -Name $ShortcutName
        $ExistingShortcut = $null
        try {
            $ExistingShortcut = Invoke-odscexApiRequest -Resource $ShortcutResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
        } catch {
            $ExistingShortcut = $null
        }

        if ($State -eq 'Absent') {
            if (-not $ExistingShortcut) {
                return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'Remove' -Status 'AlreadyAbsent' -Message 'Shortcut was already absent.' -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
            }

            if (-not $ExistingShortcut.remoteItem) {
                Write-Error "Existing item '$ShortcutName' for '$User' is not a OneDrive shortcut." -ErrorAction Stop
            }

            if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Removing shortcut '$ShortcutName'")) {
                Invoke-odscexApiRequest -Resource $ShortcutResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete) | Out-Null
                return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'Remove' -Status 'Removed' -Response $ExistingShortcut -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
            }

            return
        }

        if ($ExistingShortcut) {
            $ExistingIds = $ExistingShortcut.remoteItem.sharepointIds
            $MatchesTarget = $ExistingShortcut.remoteItem -and
                ($ExistingIds.listId -eq $Target.DocumentLibraryId) -and
                ($ExistingIds.listItemUniqueId -eq $Target.ItemUniqueId) -and
                ($ExistingIds.siteId -eq $Target.SiteId) -and
                ($ExistingIds.webId -eq $Target.WebId)

            if ($MatchesTarget) {
                return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'None' -Status 'Compliant' -Response $ExistingShortcut -Message 'Shortcut already points to the requested target.' -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
            }

            switch ($ConflictAction) {
                'Skip' {
                    return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'None' -Status 'SkippedConflict' -Response $ExistingShortcut -Message 'An item with the requested shortcut name already exists.' -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
                }
                'Error' {
                    Write-Error "An item named '$ShortcutName' already exists for '$User' and does not match the requested target." -ErrorAction Stop
                }
                'Replace' {
                    if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Replacing shortcut '$ShortcutName'")) {
                        Invoke-odscexApiRequest -Resource $ShortcutResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete) | Out-Null
                        $ExistingShortcut = $null
                    } else {
                        return
                    }
                }
                'Rename' {
                    $ShortcutName = "$ShortcutName-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
                    $ShortcutResource = Join-odscexDrivePathResource -User $User -RelativePath $RelativePath -Name $ShortcutName
                }
            }
        }

        $CreateRequest = @{
            Resource = "users/${User}/drive/root/children"
            Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
            Body = @{
                name = $ShortcutName
                remoteItem = @{
                    sharepointIds = @{
                        listId = $Target.DocumentLibraryId
                        listItemUniqueId = $Target.ItemUniqueId
                        siteId = $Target.SiteId
                        siteUrl = $Target.SiteUrl
                        webId = $Target.WebId
                    }
                }
                '@microsoft.graph.conflictBehavior' = if ($ConflictAction -eq 'Rename') { 'rename' } else { 'fail' }
            } | ConvertTo-Json -Depth 20
        }

        if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Creating shortcut '$ShortcutName'")) {
            $FolderResponse = $null

            if ($RelativePath) {
                $FolderResponse = Resolve-odscexDriveFolderPath -User $User -RelativePath $RelativePath -Create
                if (-not $FolderResponse) {
                    Write-Error "Error resolving OneDrive folder path '$RelativePath' for ${User}." -ErrorAction Stop
                }

                # Microsoft Graph only accepts Add shortcut to OneDrive payloads at the
                # drive root. Create the shortcut there with a temporary name, then move
                # it into the requested OneDrive folder and apply the final name.
                $CreateRequest.Body = @{
                    name = "odscex-$([guid]::NewGuid().ToString('N'))"
                    remoteItem = @{
                        sharepointIds = @{
                            listId = $Target.DocumentLibraryId
                            listItemUniqueId = $Target.ItemUniqueId
                            siteId = $Target.SiteId
                            siteUrl = $Target.SiteUrl
                            webId = $Target.WebId
                        }
                    }
                    '@microsoft.graph.conflictBehavior' = 'rename'
                } | ConvertTo-Json -Depth 20
            }

            $ShortcutResponse = Invoke-odscexApiRequest @CreateRequest

            if (!($ShortcutResponse)) {
                Write-Error "Error creating OneDrive shortcut '$($ShortcutName)' for ${User}." -ErrorAction Stop
            }

            $UpdateBody = @{ name = $ShortcutName }
            if ($FolderResponse) {
                $UpdateBody.parentReference = @{ id = $FolderResponse.id }
            }

            $RenameRequest = @{
                Resource = "users/${User}/drive/items/$($ShortcutResponse.id)"
                Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Patch
                Body = $UpdateBody | ConvertTo-Json -Depth 10
            }

            try {
                $ShortcutResponse = Invoke-odscexApiRequest @RenameRequest
            } catch {
                if ($FolderResponse -and $ShortcutResponse.id) {
                    try {
                        Invoke-odscexApiRequest -Resource "users/${User}/drive/items/$($ShortcutResponse.id)" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete) | Out-Null
                    } catch {
                        Write-Verbose "Failed to clean up temporary OneDrive shortcut '$($ShortcutResponse.id)' after move failure."
                    }
                }

                Write-Error "Created OneDrive shortcut '$($ShortcutResponse.name)' but failed to move or rename it to '$ShortcutName'. $($_.Exception.Message)" -ErrorAction Stop
            }

            if ($PassThru) {
                return $ShortcutResponse
            }

            return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'Create' -Status 'Created' -Response $ShortcutResponse -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
        }
    }
}
