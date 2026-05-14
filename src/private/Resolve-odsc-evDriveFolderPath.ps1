function Resolve-odsc-evDriveFolderPath {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $User,

        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $false)]
        [switch] $Create
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return Invoke-odsc-evApiRequest -Resource "users/${User}/drive/root" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
    }

    $Segments = $RelativePath -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $CurrentResource = "users/${User}/drive/root"
    $CurrentItem = Invoke-odsc-evApiRequest -Resource $CurrentResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)

    foreach ($Segment in $Segments) {
        $EncodedSegment = [uri]::EscapeDataString($Segment)
        $ChildResource = "users/${User}/drive/items/$($CurrentItem.id):/${EncodedSegment}:"
        $Child = $null

        try {
            $Child = Invoke-odsc-evApiRequest -Resource $ChildResource -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -ErrorAction Stop
        } catch {
            if (-not $Create) {
                Write-Error "OneDrive folder path '$RelativePath' was not found for '$User'." -ErrorAction Stop
            }
        }

        if (-not $Child) {
            $CreateRequest = @{
                Resource = "users/${User}/drive/items/$($CurrentItem.id)/children"
                Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
                Body = @{
                    name = $Segment
                    folder = @{}
                    '@microsoft.graph.conflictBehavior' = 'fail'
                } | ConvertTo-Json -Depth 10
            }

            if ($PSCmdlet.ShouldProcess("${User}'s OneDrive", "Creating folder '$Segment' in '$RelativePath'")) {
                $Child = Invoke-odsc-evApiRequest @CreateRequest
            }
        }

        $CurrentItem = $Child
    }

    return $CurrentItem
}
