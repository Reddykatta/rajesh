#PowerShell.exe -ExecutionPolicy Bypass -File "C:\
# Prompt for input options
$domainName = Read-Host "Enter the name of the domain"
$groupName = Read-Host "Enter the name of the Active Directory group to add/remove users from"

# Prompt for credentials to use for adding/removing members
$modifyCredentials = Get-Credential -Message "Enter the credentials to modify the group members"

# Retrieve the members of the specified group
$groupMembers = Get-ADGroupMember -Identity $groupName -Server $domainName

# Display the current members of the group with Name, GivenName, and SamAccountName properties
Write-Output "Current members of group '$groupName' in domain '$domainName':"
$groupMembers | ForEach-Object {
    $user = Get-ADUser -Identity $_.SamAccountName -Server $domainName -Properties GivenName, SamAccountName
    if ($user) {
        $user | Select-Object Name, GivenName, SamAccountName
    }
}

# Prompt for the action to perform (Add or Remove)
$action = Read-Host "Enter 'Add' to add users or 'Remove' to remove users from the group"

switch ($action) {
    "Add" {
        # Prompt for the users to add
        $usersToAdd = Read-Host "Enter the usernames of the members you want to add (separated by comma)"

        # Convert the string of usernames to an array
        $usersToAddArray = $usersToAdd -split ',' | ForEach-Object { $_.Trim() }

        # Retrieve the detailed information of the members to add
        $membersToAdd = $usersToAddArray | Get-ADUser -Server $domainName -Properties GivenName, SamAccountName

        # Add the selected members to the group using the provided credentials
        $membersToAdd | ForEach-Object {
            $user = Get-ADUser -Identity $_.SamAccountName -Server $domainName -Credential $modifyCredentials
            if ($user) {
                try {
                    Add-ADGroupMember -Identity $groupName -Members $user -Server $domainName -Credential $modifyCredentials
                    Write-Output "Added member $($_.Name) ($($_.SamAccountName)) to group '$groupName' in domain '$domainName'"
                }
                catch {
                    Write-Output "Failed to add member $($_.Name) ($($_.SamAccountName)): $_"
                }
            } else {
                Write-Output "User $($_.Name) ($($_.SamAccountName)) not found"
            }
        }
    }
    "Remove" {
        # Prompt for the users to remove
        $usersToRemove = Read-Host "Enter the usernames of the members you want to remove (separated by comma)"

        # Convert the string of usernames to an array
        $usersToRemoveArray = $usersToRemove -split ',' | ForEach-Object { $_.Trim() }

        # Retrieve the detailed information of the members to remove
        $membersToRemove = $groupMembers | Where-Object { $usersToRemoveArray -contains $_.SamAccountName } | Get-ADUser -Properties GivenName, SamAccountName

        # Remove the selected members from the group using the provided credentials
        $membersToRemove | ForEach-Object {
            $user = Get-ADUser -Identity $_.SamAccountName -Server $domainName -Credential $modifyCredentials
            if ($user) {
                try {
                    Remove-ADGroupMember -Identity $groupName -Members $user -Confirm:$false -Server $domainName -Credential $modifyCredentials
                    Write-Output "Removed member $($_.Name) ($($_.SamAccountName)) from group '$groupName' in domain '$domainName'"
                }
                catch {
                    Write-Output "Failed to remove member $($_.Name) ($($_.SamAccountName)): $_"
                }
            } else {
                Write-Output "User $($_.Name) ($($_.SamAccountName)) not found"
            }
        }
    }
    default {
        Write-Output "Invalid action specified. Please choose 'Add' or 'Remove'."
    }
}
