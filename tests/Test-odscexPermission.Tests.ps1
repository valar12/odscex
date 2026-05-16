BeforeAll {
    . "$PSScriptRoot/../src/private/Get-odscexGraphStatusCode.ps1"
    . "$PSScriptRoot/../src/public/Test-odscexPermission.ps1"
}

Describe 'Test-odscexPermission' {
    It 'returns a group membership permission check failure with actionable guidance on 403' {
        function Invoke-odscexApiRequest {
            param(
                [string] $Resource,
                [Microsoft.PowerShell.Commands.WebRequestMethod] $Method
            )

            if ($Resource -eq 'organization') {
                return [pscustomobject]@{ id = 'tenant' }
            }

            if ($Resource -like 'groups/group-id/transitiveMembers*') {
                throw 'StatusCode: 403'
            }
        }

        $Result = Test-odscexPermission -GroupId 'group-id'
        $GroupCheck = $Result | Where-Object { $_.Check -eq 'GroupMemberAccess' }

        $GroupCheck.Status | Should -Be 'Failed'
        $GroupCheck.Message | Should -BeLike '*GroupMember.Read.All*'
        $GroupCheck.Message | Should -BeLike '*Directory.Read.All*'
        $GroupCheck.Message | Should -BeLike '*Member.Read.Hidden*'
    }
}
