function Get-odscexTargetUser {
    [CmdletBinding(DefaultParameterSetName = 'AllUsers')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Csv')]
        [string] $CsvPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Group')]
        [string] $GroupId,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string] $Filter,

        [Parameter(Mandatory = $true, ParameterSetName = 'AllUsers')]
        [switch] $AllUsers
    )

    process {
        switch ($PsCmdlet.ParameterSetName) {
            'Csv' {
                Import-Csv -Path $CsvPath | ForEach-Object {
                    [pscustomobject]@{
                        UserPrincipalName = $_.UserPrincipalName
                        UserObjectId = if ($_.UserObjectId) { $_.UserObjectId } else { $_.Id }
                        Source = $CsvPath
                    }
                }
            }
            'Group' {
                try {
                    Invoke-odscexApiRequest -Resource "groups/${GroupId}/transitiveMembers/microsoft.graph.user?`$select=id,userPrincipalName,mail,accountEnabled" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages -ErrorAction Stop | ForEach-Object {
                        [pscustomobject]@{
                            UserPrincipalName = $_.userPrincipalName
                            UserObjectId = $_.id
                            Mail = $_.mail
                            AccountEnabled = $_.accountEnabled
                            Source = $GroupId
                        }
                    }
                } catch {
                    Stop-odscexGraphError -ErrorRecord $_ `
                        -ForbiddenMessage "Unable to read transitive user members for group '$GroupId'. Microsoft Graph returned 403. Grant admin consent for GroupMember.Read.All, or use a broader equivalent such as Group.Read.All or Directory.Read.All. Hidden membership groups also require Member.Read.Hidden." `
                        -FallbackMessage "Unable to resolve users from group '$GroupId'."
                }
            }
            'Filter' {
                $EncodedFilter = [uri]::EscapeDataString($Filter)
                Invoke-odscexApiRequest -Resource "users?`$filter=${EncodedFilter}&`$select=id,userPrincipalName,mail,accountEnabled" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages | ForEach-Object {
                    [pscustomobject]@{
                        UserPrincipalName = $_.userPrincipalName
                        UserObjectId = $_.id
                        Mail = $_.mail
                        AccountEnabled = $_.accountEnabled
                        Source = $Filter
                    }
                }
            }
            'AllUsers' {
                $null = $AllUsers
                Invoke-odscexApiRequest -Resource 'users?$select=id,userPrincipalName,mail,accountEnabled' -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages | ForEach-Object {
                    [pscustomobject]@{
                        UserPrincipalName = $_.userPrincipalName
                        UserObjectId = $_.id
                        Mail = $_.mail
                        AccountEnabled = $_.accountEnabled
                        Source = 'AllUsers'
                    }
                }
            }
        }
    }
}
