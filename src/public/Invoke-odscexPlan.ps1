function Invoke-odscexPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $Config = switch ($Extension) {
        '.json' { Get-Content -Path $Path -Raw | ConvertFrom-Json }
        '.psd1' { Import-PowerShellDataFile -Path $Path }
        default { Write-Error 'Supported plan formats are .json and .psd1.' -ErrorAction Stop }
    }

    $Shortcuts = if ($Config.shortcuts) { $Config.shortcuts } else { $Config.Shortcuts }
    foreach ($Shortcut in $Shortcuts) {
        [pscustomobject]@{
            Name = $Shortcut.name
            Uri = $Shortcut.siteUrl
            DocumentLibrary = $Shortcut.library
            DocumentLibraryId = $Shortcut.libraryId
            FolderPath = $Shortcut.folderPath
            RelativePath = $Shortcut.oneDrivePath
            State = if ($Shortcut.state) { $Shortcut.state } else { 'Present' }
            Target = $Shortcut.target
        }
    }
}
