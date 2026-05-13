# CHANGELOG

## 0.5.1

* Added `Connect-odsc -Cloud` support for Microsoft Graph Global, GCC, GCC High, DoD, and China endpoints.
* Added Graph endpoint selection for national clouds so API requests use the connected cloud's Microsoft Graph root endpoint.
* Added optional `-GraphEndpoint` override for advanced/custom national-cloud endpoint scenarios.

## 0.5.0

* Added organization-scale shortcut assignment commands: `Get-odscTargetUser`, `Set-odscShortcutState`, `Invoke-odscShortcutAssignment`, `Invoke-odscPlan`, `Invoke-odscApply`, `Invoke-odscGraphBatch`, and `Test-odscPermission`.
* Added idempotent desired-state behavior with configurable conflict actions.
* Added Microsoft Graph retry/backoff handling, pagination support, and a JSON batch helper.
* Added safer OneDrive path encoding, folder-path resolution, and exact document-library matching with ambiguity protection.
* Added pipeline-friendly user parameters, structured shortcut result objects, and CSV/JSON/CLIXML report output.
* Improved module import style and bumped the module version to 0.5.0.

## 0.4.1

* Fixed a security warning in WindowsPowerShell triggered by `Invoke-WebRequest` calls missing the `-UseBasicParsing` parameter.

## 0.4.0

* Add feature to create / get / remove shortcuts in OneDrive's subfolder

## 0.3.0

* Change endpoint `/drives/{idOrUserPrincipalName}` to `/users/{idOrUserPrincipalName}/drive`
* New command: `Get-odscDrive`
* Ease use in scripts by removing Stop on some errors
* Ensure that `Remove-odsc` removes a remoteItem-type resource
* Move token to global script variable for better interaction in scripts
* Other minor fixes and updates

## 0.2.1

* Add rename request to name shortcut exactly as passed to the script
* Change leading blank spaces to tabs
* Refactor from OneDriveShortcut to odsc. Commands now are: `Connect-odsc`, `Disconnect-odsc`, `Get-odsc`, `New-odsc`, `Remove-odsc`. API is `Invoke-odscApiRequest`

## 0.1.1

*   Fixed issue [#1](https://github.com/derpenstiltskin/onedriveshortcuts/issues/1#issue-1504890237) by adding option to specify AzureCloudInstance when connecting

## 0.1.0

*   Initial release
*   Commands: `Connect-ODS`, `Disconnect-ODS`, `Get-OneDriveShortcut`, `New-OneDriveShortcut`, `Remove-OneDriveShortcut`
