function Resolve-odscexDocumentLibrary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SiteIdRaw,

        [Parameter(Mandatory = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibrary,

        [Parameter(Mandatory = $false)]
        [string] $DocumentLibraryId,

        [Parameter(Mandatory = $false)]
        [switch] $AllowAmbiguousLibraryMatch
    )

    if ($DocumentLibraryId) {
        try {
            $DocumentLibraryResponse = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists/${DocumentLibraryId}" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
        } catch {
            Stop-odscexGraphError -ErrorRecord $_ `
                -NotFoundMessage "Unable to find document library id '$DocumentLibraryId' in site '$Uri'. Verify the library id belongs to that site." `
                -ForbiddenMessage "Unable to access document library id '$DocumentLibraryId' in site '$Uri'. Verify Graph has permission to read lists in the site." `
                -FallbackMessage "Unable to resolve document library id '$DocumentLibraryId' in site '$Uri'."
        }
    } else {
        $EscapedLibrary = $DocumentLibrary.Replace("'", "''")
        try {
            $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=displayName eq '${EscapedLibrary}'" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages -ErrorAction Stop

            if ((!$LibraryMatches) -or ($LibraryMatches.Count -eq 0)) {
                $LibraryMatches = Invoke-odscexApiRequest -Resource "sites/${SiteIdRaw}/lists?`$filter=startsWith(displayName,'${EscapedLibrary}')" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages -ErrorAction Stop
            }
        } catch {
            Stop-odscexGraphError -ErrorRecord $_ `
                -ForbiddenMessage "Unable to search document libraries in site '$Uri'. Microsoft Graph returned 403. Verify Graph has permission to read lists in the site." `
                -FallbackMessage "Unable to search document libraries in site '$Uri'."
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

    return $DocumentLibraryResponse
}
