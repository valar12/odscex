BeforeAll {
    . "$PSScriptRoot/../src/private/Get-odscexGraphStatusCode.ps1"
    . "$PSScriptRoot/../src/private/Stop-odscexGraphError.ps1"
    . "$PSScriptRoot/../src/public/Get-odscexTargetUser.ps1"
}

Describe 'Get-odscexTargetUser' {
    It 'explains required Graph permissions when group transitiveMembers returns 403' {
        function Invoke-odscexApiRequest {
            param(
                [string] $Resource,
                [Microsoft.PowerShell.Commands.WebRequestMethod] $Method,
                [switch] $AllPages
            )

            if ($Resource -like 'groups/group-id/transitiveMembers*') {
                throw 'StatusCode: 403'
            }
        }

        { Get-odscexTargetUser -GroupId 'group-id' -ErrorAction Stop } |
            Should -Throw '*GroupMember.Read.All*Directory.Read.All*Member.Read.Hidden*'
    }
}
