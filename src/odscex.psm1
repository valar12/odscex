#Requires -Version 5.1
#Requires -Modules MSAL.PS
$Public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public/*.ps1') -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'private/*.ps1') -ErrorAction SilentlyContinue)

$script:ODSCEXToken = $null
$script:ODSCEXCloudEnvironment = 'Global'
$script:ODSCEXGraphEndpoint = 'https://graph.microsoft.com'

foreach ($Import in @($Private + $Public)) {
    Write-Verbose "Importing file: $($Import.FullName)"
    . $Import.FullName
}

foreach ($File in $Public) {
    Export-ModuleMember -Function $File.BaseName
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose 'Clearing odscex authentication token'
    $script:ODSCEXToken = $null
    $script:ODSCEXCloudEnvironment = 'Global'
    $script:ODSCEXGraphEndpoint = 'https://graph.microsoft.com'
}
