# Prompt for input options
$domainName = Read-Host "Enter the name of the domain"
$groupName = Read-Host "Enter the name of the Active Directory security group"

# Retrieve the members of the specified group
$groupMembers = Get-ADGroupMember -Identity $groupName -Server $domainName

# Display the list of users in the group with account status
$users = $groupMembers | ForEach-Object {
    $user = Get-ADUser -Identity $_.SamAccountName -Server $domainName -Properties GivenName, SamAccountName, Enabled
    if ($user) {
        $accountStatus = if ($user.Enabled) { "Enabled" } else { "Disabled" }
        $user | Select-Object Name, GivenName, SamAccountName, @{Name="AccountStatus"; Expression={$accountStatus}}
    }
}

# Prompt for a place to save the results
$outputPath = Read-Host "Enter a path to save the results"

if ([string]::IsNullOrWhiteSpace($outputPath)) {
    # Display the results directly
    $users
}
else {
    # Save the results to a file
    $users | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Output "Results saved to $outputPath"
}
