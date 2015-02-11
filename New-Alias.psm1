Function New-Alias($name)
{
    $alias = $name.tolower()
    $checkGroup = Get-DistributionGroup -Identity $name -ErrorAction 'SilentlyContinue'
    Write-Host "List of path to select from" 
    $path = Read-Host "Enter the location where the alias will reside from the list above"
    switch ($path)
    {
        InternalGroups {$OU = "list/path/to/where/groups/are/stored"}
        Scripted {$OU = "list/path/to/where/groups/are/stored"}
        DidItDM {$OU = "list/path/to/where/groups/are/stored"}
        HLD {$OU = "list/path/to/where/groups/are/stored"}
        other {$OU = Read-Host "Enter the location of where you wish this group to be stored"}
    }
     
    if ($checkGroup.IsValid -eq $True)
    {
         Write-Host "Group already exists" -ForegroundColor DarkRed -BackgroundColor Black
         Write-Host "Check the name or have requester submit new name" -ForegroundColor DarkRed -BackgroundColor Black
         Break
    }
    else 
    {
        $requesterInfo = Read-Host "Enter the requesters First Initial. Last Name > "
        $date = Get-Date -UFormat %m/%d/%Y
        $ticketNum = Read-Host "Enter Ticket Number (Without #) > "
        $notes = "Requested by $requesterInfo on $date #$ticketNum"
        New-DistributionGroup -Name "$name" -Alias "$alias" -type "Security" -OrganizationalUnit $OU -Notes $notes  
    }
    
    # There's a delay before exchange recognizes the new distribution group created via PS.
    # This is my solution so powershell doesn't throw out an error.
    $count = 0
    do 
    {
        $count++
        Write-Progress -Activity "Progress Bar" -Status "$count percent" -PercentComplete $count
        Start-Sleep 1
        if ($count -gt 100)
        {
            Write-Host "Timed out" -ForegroundColor DarkRed -BackgroundColor Black
            Write-Host "Check the event logs" -ForegroundColor DarkRed -BackgroundColor Black
            Break
        }
    }
    until ((Get-DistributionGroup -Identity $name -ErrorAction 'SilentlyContinue').IsValid -eq $True)
    Get-DistributionGroup -Identity $name | Select-Object name, managedby
    Get-Group -Identity $name | Select-Object notes

    Set-AliasInfo
    Add-AliasMember
}

Function Set-AliasInfo 
{
    if([string]::IsNullOrEmpty($name))
    {
        $name = Read-Host "Enter name of distribution group here "
    }

    $mods = "admin names"
    Set-DistributionGroup -Identity $name -ManagedBy $mods -RequireSenderAuthenticationEnabled $false -HiddenFromAddressListsEnabled $true 
}

Function Add-AliasMember
{
    if([string]::IsNullOrEmpty($name))
    {
        $name = Read-Host "Enter name of distribution group here "
    }
    $memberslist = @() 
    $memcount = 1
    do{
        $input = Read-Host "Enter names of members to be part of distribution group (seperate lines) $memcount "
        $i++
        if ($input -ne "")
        {
            $memberslist += $input
        }
    }
    until ($input -eq "")
    foreach ($member in $memberslist)
    {
        Add-DistributionGroupMember -Identity $name -Member $member
    }
}
