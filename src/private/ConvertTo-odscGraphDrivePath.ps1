function ConvertTo-odscGraphDrivePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $InvalidCharacters = [char[]]'"*:<>?|'
    $Segments = $Path -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($Segment in $Segments) {
        if ($Segment.IndexOfAny($InvalidCharacters) -ge 0) {
            Write-Error "OneDrive path segment '$Segment' contains an unsupported character." -ErrorAction Stop
        }
    }

    return (($Segments | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
}
