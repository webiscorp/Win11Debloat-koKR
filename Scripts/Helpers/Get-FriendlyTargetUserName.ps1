<#
    .SYNOPSIS
        Returns a readable description of the current app-removal target.
#>
function Get-FriendlyTargetUserName {
    $target = Get-TargetUserForAppRemoval

    switch ($target) {
        "AllUsers" { return (Get-Translation -Key 'HelperTargetAllUsers') }
        "CurrentUser" { return (Get-Translation -Key 'HelperTargetCurrentUser') }
        default { return (Get-Translation -Key 'HelperTargetNamedUser' -FormatArgs @($target)) }
    }
}
