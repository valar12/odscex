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
            $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
            if ($StatusCode -eq 404) {
                $ExistingShortcut = $null
            } elseif ($StatusCode -eq 403) {
                Write-Error "Unable to check for existing shortcut '$ShortcutName' for '$User'. Microsoft Graph returned 403 for $ShortcutResource. Verify permission to read the user's OneDrive." -ErrorAction Stop
            } else {
                Write-Error "Unable to check for existing shortcut '$ShortcutName' for '$User'. $($_.Exception.Message)" -ErrorAction Stop
            }
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
            $MatchesTargetSharePointIds = $Target.ItemUniqueId -and
                $ExistingShortcut.remoteItem -and
                ($ExistingIds.listId -eq $Target.DocumentLibraryId) -and
                ($ExistingIds.listItemUniqueId -eq $Target.ItemUniqueId) -and
                ($ExistingIds.siteId -eq $Target.SiteId) -and
                ($ExistingIds.webId -eq $Target.WebId)
            $MatchesTargetDriveItem = $Target.DriveId -and
                $Target.DriveItemId -and
                $ExistingShortcut.remoteItem -and
                ($ExistingShortcut.remoteItem.id -eq $Target.DriveItemId) -and
                ($ExistingShortcut.remoteItem.parentReference.driveId -eq $Target.DriveId)
            $MatchesTarget = $MatchesTargetSharePointIds -or $MatchesTargetDriveItem

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

        $OneDriveRoot = Resolve-odscexOneDriveRoot -User $User

        if ($Target.ItemUniqueId) {
            $RemoteItem = @{
                sharepointIds = @{
                    listId = $Target.DocumentLibraryId
                    listItemUniqueId = $Target.ItemUniqueId
                    siteId = $Target.SiteId
                    siteUrl = $Target.SiteUrl
                    webId = $Target.WebId
                }
            }
        } elseif ($Target.DriveId -and $Target.DriveItemId) {
            $RemoteItem = @{
                id = $Target.DriveItemId
                parentReference = @{
                    driveId = $Target.DriveId
                }
            }
        } else {
            Write-Error "Unable to build shortcut target reference for '$ShortcutName'. Microsoft Graph did not return SharePoint ids or a drive item reference for the target." -ErrorAction Stop
        }

        $OneDriveDriveId = $OneDriveRoot.parentReference.driveId
        # Prefer drive-scoped item URLs after the destination drive is known. Microsoft Graph can
        # reject remoteItem create/move requests that are routed through /users/{id}/drive.
        $RootCreateResource = if ($OneDriveDriveId) {
            "drives/${OneDriveDriveId}/items/$($OneDriveRoot.id)/children"
        } else {
            "users/${User}/drive/items/$($OneDriveRoot.id)/children"
        }
        $CreateRequest = @{
            Resource = $RootCreateResource
            Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
            Body = @{
                name = $ShortcutName
                remoteItem = $RemoteItem
                '@microsoft.graph.conflictBehavior' = if ($ConflictAction -eq 'Rename') { 'rename' } else { 'fail' }
            } | ConvertTo-Json -Depth 20
        }

        if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Creating shortcut '$ShortcutName'")) {
            $DestinationFolder = $null
            $DestinationDriveId = $null
            $MoveShortcutToDestination = $false
            if ($RelativePath) {
                $FolderResponse = Resolve-odscexDriveFolderPath -User $User -RelativePath $RelativePath -Create
                if (-not $FolderResponse) {
                    Write-Error "Error resolving OneDrive folder path '$RelativePath' for ${User}." -ErrorAction Stop
                }

                $DestinationFolder = $FolderResponse
                $DestinationDriveId = $DestinationFolder.parentReference.driveId
                if (-not $DestinationDriveId) {
                    $DestinationDriveId = $OneDriveDriveId
                }

                $CreateRequest.Resource = if ($DestinationDriveId) {
                    "drives/${DestinationDriveId}/items/$($FolderResponse.id)/children"
                } else {
                    "users/${User}/drive/items/$($FolderResponse.id)/children"
                }
            }

            try {
                $ShortcutResponse = Invoke-odscexApiRequest @CreateRequest -ErrorAction Stop
            } catch {
                $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
                if (($StatusCode -ne 400) -or (-not $DestinationFolder)) {
                    Write-Error $_ -ErrorAction Stop
                }

                Write-Verbose "Microsoft Graph rejected shortcut creation directly inside '$RelativePath'. Creating the shortcut at the OneDrive root, then moving it to the requested folder."
                $TemporaryShortcutName = "_odscex-$([Guid]::NewGuid().ToString('N'))"
                $CreateRequest.Resource = $RootCreateResource
                $CreateRequest.Body = @{
                    name = $TemporaryShortcutName
                    remoteItem = $RemoteItem
                    '@microsoft.graph.conflictBehavior' = 'fail'
                } | ConvertTo-Json -Depth 20

                $ShortcutResponse = Invoke-odscexApiRequest @CreateRequest
                $MoveShortcutToDestination = $true
            }

            if (!($ShortcutResponse)) {
                Write-Error "Error creating OneDrive shortcut '$($ShortcutName)' for ${User}." -ErrorAction Stop
            }

            try {
                if ($MoveShortcutToDestination) {
                    $ShortcutResourceById = if ($DestinationDriveId) {
                        "drives/${DestinationDriveId}/items/$($ShortcutResponse.id)"
                    } else {
                        "users/${User}/drive/items/$($ShortcutResponse.id)"
                    }

                    $MoveRequest = @{
                        Resource = $ShortcutResourceById
                        Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Patch
                        Body = @{
                            parentReference = @{
                                id = $DestinationFolder.id
                            }
                        } | ConvertTo-Json -Depth 10
                    }
                    $ShortcutResponse = Invoke-odscexApiRequest @MoveRequest -ErrorAction Stop
                }

                $ShortcutResourceById = if ($DestinationDriveId) {
                    "drives/${DestinationDriveId}/items/$($ShortcutResponse.id)"
                } elseif ($OneDriveDriveId) {
                    "drives/${OneDriveDriveId}/items/$($ShortcutResponse.id)"
                } else {
                    "users/${User}/drive/items/$($ShortcutResponse.id)"
                }

                $RenameRequest = @{
                    Resource = $ShortcutResourceById
                    Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Patch
                    Body = @{ name = $ShortcutName } | ConvertTo-Json -Depth 10
                }
                $ShortcutResponse = Invoke-odscexApiRequest @RenameRequest -ErrorAction Stop
            } catch {
                if ($MoveShortcutToDestination) {
                    try {
                        Invoke-odscexApiRequest -Resource $ShortcutResourceById -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete) -ErrorAction Stop | Out-Null
                    } catch {
                        Write-Verbose "Unable to clean up temporary shortcut '$($ShortcutResponse.id)' after fallback move or rename failure. $($_.Exception.Message)"
                    }
                }

                Write-Error $_ -ErrorAction Stop
            }

            if ($PassThru) {
                return $ShortcutResponse
            }

            return Write-odscexResult -User $User -ShortcutName $ShortcutName -Action 'Create' -Status 'Created' -Response $ShortcutResponse -TargetSite $Uri -TargetLibrary $DocumentLibrary -TargetFolderPath $FolderPath
        }
    }
}
