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

    try {
        $SiteUri = [uri]$Uri
    } catch {
        Write-Error "SharePoint site URI '$Uri' is not a valid URI. Specify the full https:// tenant SharePoint site URL." -ErrorAction Stop
    }

    if ((-not $SiteUri.IsAbsoluteUri) -or ($SiteUri.Scheme -ne 'https') -or [string]::IsNullOrWhiteSpace($SiteUri.Authority)) {
        Write-Error "SharePoint site URI '$Uri' is not valid. Specify the full https:// tenant SharePoint site URL." -ErrorAction Stop
    }

    $SiteDomain = $SiteUri.Authority
    $SiteResource = $SiteUri.AbsolutePath.TrimEnd('/')
    $SiteLookupResource = "sites/${SiteDomain}:${SiteResource}"

    try {
        $SiteResponse = Invoke-odscexApiRequest -Resource $SiteLookupResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
    } catch {
        $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
        if ($StatusCode -eq 404) {
            Write-Error "Unable to find SharePoint site '$Uri'. Microsoft Graph returned 404 for $SiteLookupResource. Verify the tenant host and site path are correct, and use the site URL rather than a document library or folder URL." -ErrorAction Stop
        }

        if ($StatusCode -eq 403) {
            Write-Error "Unable to access SharePoint site '$Uri'. Microsoft Graph returned 403 for $SiteLookupResource. Verify the signed-in application or user has Sites.Read.All/Sites.ReadWrite.All or equivalent permissions and access to the site." -ErrorAction Stop
        }

        Write-Error "Unable to resolve SharePoint site '$Uri'. $($_.Exception.Message)" -ErrorAction Stop
    }

    if (!($SiteResponse) -or [string]::IsNullOrWhiteSpace($SiteResponse.id)) {
        Write-Error "Error retrieving SharePoint site '$Uri'. Microsoft Graph did not return a site id." -ErrorAction Stop
    }

    $SiteIdRaw = $SiteResponse.id
    $SiteIdSplit = $SiteIdRaw.Split(',')
    if ($SiteIdSplit.Count -lt 3) {
        Write-Error "Error retrieving SharePoint site '$Uri'. Microsoft Graph returned an unexpected site id '$SiteIdRaw'." -ErrorAction Stop
    }

    $SiteId = $SiteIdSplit[1]
    $WebId = $SiteIdSplit[2]

    if ($DocumentLibraryId) {
        try {
            $DocumentLibraryResponse = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists/${DocumentLibraryId}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
        } catch {
            $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
            if ($StatusCode -eq 404) {
                Write-Error "Unable to find document library id '$DocumentLibraryId' in site '$Uri'. Verify the library id belongs to that site." -ErrorAction Stop
            }

            if ($StatusCode -eq 403) {
                Write-Error "Unable to access document library id '$DocumentLibraryId' in site '$Uri'. Verify Graph has permission to read lists in the site." -ErrorAction Stop
            }

            Write-Error "Unable to resolve document library id '$DocumentLibraryId' in site '$Uri'. $($_.Exception.Message)" -ErrorAction Stop
        }
    } else {
        $EscapedLibrary = $DocumentLibrary.Replace("'", "''")
        try {
            $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=displayName eq '${EscapedLibrary}'" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages -ErrorAction Stop

            if ((!$LibraryMatches) -or ($LibraryMatches.Count -eq 0)) {
                $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=startsWith(displayName,'${EscapedLibrary}')" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages -ErrorAction Stop
            }
        } catch {
            $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
            if ($StatusCode -eq 403) {
                Write-Error "Unable to search document libraries in site '$Uri'. Microsoft Graph returned 403. Verify Graph has permission to read lists in the site." -ErrorAction Stop
            }

            Write-Error "Unable to search document libraries in site '$Uri'. $($_.Exception.Message)" -ErrorAction Stop
        }

        if ((!$LibraryMatches) -or ($LibraryMatches.Count -eq 0)) {
            Write-Error "Error retrieving SharePoint document library '$DocumentLibrary' from '$Uri'. Verify the library display name, or specify -DocumentLibraryId." -ErrorAction Stop
        }

        if (($LibraryMatches.Count -gt 1) -and (-not $AllowAmbiguousLibraryMatch)) {
            $Names = ($LibraryMatches | ForEach-Object { $_.displayName }) -join ', '
            Write-Error "Document library name '$DocumentLibrary' matched multiple libraries: $Names. Specify -DocumentLibraryId or -AllowAmbiguousLibraryMatch." -ErrorAction Stop
        }

        $DocumentLibraryResponse = $LibraryMatches[0]
    }

    if (!($DocumentLibraryResponse) -or [string]::IsNullOrWhiteSpace($DocumentLibraryResponse.id)) {
        Write-Error "Error retrieving SharePoint document library. Microsoft Graph did not return a list id." -ErrorAction Stop
    }

    $ListTemplate = $DocumentLibraryResponse.list.template
    if ($ListTemplate -and ($ListTemplate -ne 'documentLibrary')) {
        $ListName = if ($DocumentLibraryResponse.displayName) { $DocumentLibraryResponse.displayName } else { $DocumentLibraryResponse.id }
        Write-Error "SharePoint list '$ListName' is a '$ListTemplate' list, not a document library. Specify a document library display name or id." -ErrorAction Stop
    }

    $ResolvedLibraryId = $DocumentLibraryResponse.id
    $ResolvedLibraryName = if ($DocumentLibraryResponse.name) { $DocumentLibraryResponse.name } else { $DocumentLibraryResponse.displayName }
    $ResolvedShortcutName = if ($DocumentLibrary) { $DocumentLibrary } else { $DocumentLibraryResponse.displayName }
    $ItemUniqueId = 'root'
    $ItemUniqueName = $null
    $TargetDriveId = $null
    $TargetDriveItemId = $null

    if ($FolderPath) {
        try {
            $ListDrive = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists/${ResolvedLibraryId}/drive" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
        } catch {
            $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
            if ($StatusCode -eq 404) {
                Write-Error "Unable to open the drive for document library '$ResolvedLibraryName' in site '$Uri'. Verify the selected list is a document library." -ErrorAction Stop
            }

            if ($StatusCode -eq 403) {
                Write-Error "Unable to open the drive for document library '$ResolvedLibraryName' in site '$Uri'. Microsoft Graph returned 403. Verify Files.Read.All/Files.ReadWrite.All or site permissions are granted." -ErrorAction Stop
            }

            Write-Error "Unable to open the drive for document library '$ResolvedLibraryName' in site '$Uri'. $($_.Exception.Message)" -ErrorAction Stop
        }

        $EncodedFolderPath = ConvertTo-odscexGraphDrivePath -Path $FolderPath
        try {
            $DriveItem = Invoke-odscexApiRequest -Resource "drives/$($ListDrive.id)/root:/${EncodedFolderPath}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -DoNotUsePrefer -ErrorAction Stop
        } catch {
            $StatusCode = Get-odscexGraphStatusCode -ErrorRecord $_
            if ($StatusCode -eq 404) {
                Write-Error "Unable to find folder '$FolderPath' in document library '$ResolvedLibraryName' on site '$Uri'. Verify the path is relative to the library root and does not include the library name." -ErrorAction Stop
            }

            if ($StatusCode -eq 403) {
                Write-Error "Unable to access folder '$FolderPath' in document library '$ResolvedLibraryName' on site '$Uri'. Microsoft Graph returned 403. Verify permissions to the folder." -ErrorAction Stop
            }

            Write-Error "Unable to resolve folder '$FolderPath' in document library '$ResolvedLibraryName' on site '$Uri'. $($_.Exception.Message)" -ErrorAction Stop
        }

        if (!($DriveItem) -or [string]::IsNullOrWhiteSpace($DriveItem.id)) {
            Write-Error "Error retrieving document library folder '$FolderPath'. Microsoft Graph did not return a drive item id for the folder." -ErrorAction Stop
        }

        if ($DriveItem.sharepointIds -and (-not [string]::IsNullOrWhiteSpace($DriveItem.sharepointIds.listItemUniqueId))) {
            $ItemUniqueId = $DriveItem.sharepointIds.listItemUniqueId
        } else {
            $ItemUniqueId = $null
            Write-Verbose "Microsoft Graph did not return SharePoint ids for folder '$FolderPath'. Falling back to the drive item reference."
        }

        $TargetDriveId = $ListDrive.id
        $TargetDriveItemId = $DriveItem.id
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
        DriveId = $TargetDriveId
        DriveItemId = $TargetDriveItemId
    }
}
