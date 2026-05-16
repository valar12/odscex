BeforeAll {
    . "$PSScriptRoot/../src/private/Get-odscexGraphStatusCode.ps1"
    . "$PSScriptRoot/../src/private/Join-odscexDrivePathResource.ps1"
    . "$PSScriptRoot/../src/private/ConvertTo-odscexGraphDrivePath.ps1"
    . "$PSScriptRoot/../src/private/Write-odscexResult.ps1"
    . "$PSScriptRoot/../src/public/Set-odscexShortcutState.ps1"
}

Describe 'Set-odscexShortcutState' {
    It 'moves a fallback-created shortcut before renaming when Graph rejects direct nested creation' {
        $script:Requests = [System.Collections.Generic.List[object]]::new()

        function Resolve-odscexShortcutTarget {
            [pscustomobject]@{
                DefaultShortcutName = '2025-06-25'
                DriveId = 'target-drive'
                DriveItemId = 'target-item'
            }
        }

        function Resolve-odscexOneDriveRoot {
            [pscustomobject]@{
                id = 'root-item'
                parentReference = [pscustomobject]@{ driveId = 'user-drive' }
            }
        }

        function Resolve-odscexDriveFolderPath {
            [pscustomobject]@{
                id = 'destination-folder'
                parentReference = [pscustomobject]@{ driveId = 'user-drive' }
            }
        }

        function Invoke-odscexApiRequest {
            param(
                [string] $Resource,
                [Microsoft.PowerShell.Commands.WebRequestMethod] $Method,
                [string] $Body
            )

            $script:Requests.Add([pscustomobject]@{ Resource = $Resource; Method = $Method; Body = $Body }) | Out-Null

            if ($Resource -eq 'users/user@contoso.com/drive/root:/Shortcuts/2025-06-25' -and $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get) {
                throw 'StatusCode: 404'
            }

            if ($Resource -eq 'users/user@contoso.com/drive/items/destination-folder/children' -and $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post) {
                throw 'StatusCode: 400'
            }

            if ($Resource -eq 'users/user@contoso.com/drive/items/root-item/children' -and $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post) {
                return [pscustomobject]@{ id = 'temporary-shortcut' }
            }

            if ($Resource -eq 'users/user@contoso.com/drive/items/temporary-shortcut' -and $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Patch) {
                return [pscustomobject]@{ id = 'temporary-shortcut' }
            }
        }

        Set-odscexShortcutState -Uri 'https://contoso.sharepoint.com' -DocumentLibrary 'Documents' -FolderPath '2025-06-25' -RelativePath 'Shortcuts' -UserPrincipalName 'user@contoso.com' -Confirm:$false | Out-Null

        $PatchRequests = @($script:Requests | Where-Object { $_.Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Patch })
        $PatchRequests | Should -HaveCount 2

        $MoveBody = $PatchRequests[0].Body | ConvertFrom-Json
        $MoveBody.parentReference.id | Should -Be 'destination-folder'
        $MoveBody.parentReference.driveId | Should -Be 'user-drive'
        $MoveBody.PSObject.Properties.Name | Should -Not -Contain 'name'

        $RenameBody = $PatchRequests[1].Body | ConvertFrom-Json
        $RenameBody.name | Should -Be '2025-06-25'
        $RenameBody.PSObject.Properties.Name | Should -Not -Contain 'parentReference'
    }
}
