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

    $SiteUri = [uri]$Uri
    $SiteDomain = $SiteUri.Authority
    $SiteResource = $SiteUri.AbsolutePath.TrimEnd('/')

    $SiteResponse = Invoke-odscexApiRequest -Resource "sites/${SiteDomain}:${SiteResource}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
    if (!($SiteResponse)) {
        Write-Error "Error retrieving SharePoint site '$Uri'." -ErrorAction Stop
    }

    $SiteIdRaw = $SiteResponse.id
    $SiteIdSplit = $SiteIdRaw.Split(',')
    $SiteId = $SiteIdSplit[1]
    $WebId = $SiteIdSplit[2]

    if ($DocumentLibraryId) {
        $DocumentLibraryResponse = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists/${DocumentLibraryId}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
    } else {
        $EscapedLibrary = $DocumentLibrary.Replace("'", "''")
        $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=displayName eq '${EscapedLibrary}'" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages

        if ((!$LibraryMatches) -or ($LibraryMatches.Count -eq 0)) {
            $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=startsWith(displayName,'${EscapedLibrary}')" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages
        }

        if ((!$LibraryMatches) -or ($LibraryMatches.Count -eq 0)) {
            Write-Error "Error retrieving SharePoint document library '$DocumentLibrary'." -ErrorAction Stop
        }

        if (($LibraryMatches.Count -gt 1) -and (-not $AllowAmbiguousLibraryMatch)) {
            $Names = ($LibraryMatches | ForEach-Object { $_.displayName }) -join ', '
            Write-Error "Document library name '$DocumentLibrary' matched multiple libraries: $Names. Specify -DocumentLibraryId or -AllowAmbiguousLibraryMatch." -ErrorAction Stop
        }

        $DocumentLibraryResponse = $LibraryMatches[0]
    }

    $ResolvedLibraryId = $DocumentLibraryResponse.id
    $ResolvedLibraryName = if ($DocumentLibraryResponse.name) { $DocumentLibraryResponse.name } else { $DocumentLibraryResponse.displayName }
    $ResolvedShortcutName = if ($DocumentLibrary) { $DocumentLibrary } else { $DocumentLibraryResponse.displayName }
    $ItemUniqueId = 'root'
    $ItemUniqueName = $null

    if ($FolderPath) {
        $ListDrive = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists/${ResolvedLibraryId}/drive" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
        $EncodedFolderPath = ConvertTo-odscexGraphDrivePath -Path $FolderPath
        $DriveItem = Invoke-odscexApiRequest -Resource "drives/$($ListDrive.id)/root:/${EncodedFolderPath}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -DoNotUsePrefer

        if (!($DriveItem)) {
            Write-Error "Error retrieving document library folder '$FolderPath'." -ErrorAction Stop
        }

        $ItemUniqueId = $DriveItem.sharepointIds.listItemUniqueId
        $ItemUniqueName = $DriveItem.name
        $ResolvedShortcutName = $ItemUniqueName
    }

    [pscustomobject]@{
        SiteIdRaw = $SiteIdRaw
        SiteId = $SiteId
        WebId = $WebId
        SiteUrl = $Uri
        DocumentLibraryId = $ResolvedLibraryId
        DocumentLibraryName = $ResolvedLibraryName
        DefaultShortcutName = $ResolvedShortcutName
        ItemUniqueId = $ItemUniqueId
        ItemUniqueName = $ItemUniqueName
    }
}
