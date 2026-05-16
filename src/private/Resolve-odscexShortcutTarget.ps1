function Resolve-odscexShortcutTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibraryId,

        [Parameter(Mandatory = $false)]
        [string] $FolderPath,

        [Parameter(Mandatory = $false)]
        [switch] $AllowAmbiguousLibraryMatch
    )

    $Site = Resolve-odscexSharePointSite -Uri $Uri
    $DocumentLibraryResponse = Resolve-odscexDocumentLibrary -SiteIdRaw $Site.SiteIdRaw -Uri $Uri -DocumentLibrary $DocumentLibrary -DocumentLibraryId $DocumentLibraryId -AllowAmbiguousLibraryMatch:$AllowAmbiguousLibraryMatch

    $ResolvedLibraryId = $DocumentLibraryResponse.id
    $ResolvedLibraryName = if ($DocumentLibraryResponse.name) { $DocumentLibraryResponse.name } else { $DocumentLibraryResponse.displayName }
    $ResolvedShortcutName = if ($DocumentLibrary) { $DocumentLibrary } else { $DocumentLibraryResponse.displayName }
    $ItemUniqueId = 'root'
    $ItemUniqueName = $null
    $TargetDriveId = $null
    $TargetDriveItemId = $null

    if ($FolderPath) {
        $Folder = Resolve-odscexDocumentLibraryFolder -SiteIdRaw $Site.SiteIdRaw -Uri $Uri -DocumentLibraryId $ResolvedLibraryId -DocumentLibraryName $ResolvedLibraryName -FolderPath $FolderPath
        $DriveItem = $Folder.Item

        if ($DriveItem.sharepointIds -and (-not [string]::IsNullOrWhiteSpace($DriveItem.sharepointIds.listItemUniqueId))) {
            $ItemUniqueId = $DriveItem.sharepointIds.listItemUniqueId
        } else {
            $ItemUniqueId = $null
            Write-Verbose "Microsoft Graph did not return SharePoint ids for folder '$FolderPath'. Falling back to the drive item reference."
        }

        $TargetDriveId = $Folder.Drive.id
        $TargetDriveItemId = $DriveItem.id
        $ItemUniqueName = $DriveItem.name
        $ResolvedShortcutName = $ItemUniqueName
    }

    [pscustomobject]@{
        SiteIdRaw = $Site.SiteIdRaw
        SiteId = $Site.SiteId
        WebId = $Site.WebId
        SiteUrl = $Uri
        DocumentLibraryId = $ResolvedLibraryId
        DocumentLibraryName = $ResolvedLibraryName
        DefaultShortcutName = $ResolvedShortcutName
        ItemUniqueId = $ItemUniqueId
        ItemUniqueName = $ItemUniqueName
        DriveId = $TargetDriveId
        DriveItemId = $TargetDriveItemId
    }
}
