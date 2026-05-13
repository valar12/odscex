function Get-odscTargetUser {
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
                Invoke-odscApiRequest -Resource "groups/${GroupId}/transitiveMembers/microsoft.graph.user?`$select=id,userPrincipalName,mail,accountEnabled" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages | ForEach-Object {
                    [pscustomobject]@{
                        UserPrincipalName = $_.userPrincipalName
                        UserObjectId = $_.id
                        Mail = $_.mail
                        AccountEnabled = $_.accountEnabled
                        Source = $GroupId
                    }
                }
            }
            'Filter' {
                $EncodedFilter = [uri]::EscapeDataString($Filter)
                Invoke-odscApiRequest -Resource "users?`$filter=${EncodedFilter}&`$select=id,userPrincipalName,mail,accountEnabled" -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages | ForEach-Object {
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
                Invoke-odscApiRequest -Resource 'users?$select=id,userPrincipalName,mail,accountEnabled' -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -AllPages | ForEach-Object {
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
