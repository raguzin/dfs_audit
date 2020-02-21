Function Get-ResourceADGroupNamePattern {
    <#
    .SYNOPSIS
        Prepares the security group name pattern for DFS resource
    .DESCRIPTION
        Prepares the security group name pattern for DFS resource:
            prefix + resource_name + suffix
    #>
    PARAM ([String]$resource_share_server, [String]$resource_share_name, [String]$resource_path)

    if ($resource_share_server -ne '' -and $resource_share_name -ne '' -and $resource_path -ne '') {    # Check input data
        $error_str = ''
        $group_name_pattern_replace = '\\' + $resource_share_server + '\' + $resource_share_name + '\'
        if ($group_name_pattern_replace -ne ($resource_path + '\')) {   # DFS-resource folder not shared
            $group_name_pattern_replace = $group_name_pattern_replace -replace '\\','\\'
        }
        elseif ($group_name_pattern_replace -eq ($resource_path + '\')) {   # DFS-resource folder shared
            $group_name_pattern_replace = ($group_name_pattern_replace -replace ($resource_share_name + '\\')) -replace '\\','\\'
        }
        $group_name_pattern = $prefix + ($resource_path -replace $group_name_pattern_replace) + $suffix
    }
    else {
        $group_name_pattern = 'None'
        $error_str = '|Invalid DFS-resource server name or share name or target path'
    }
    
    Return @{'GroupPattern' = $group_name_pattern; 'Error' = $error_str}
}

Function Get-ResourceADGroup {
    <#
    .SYNOPSIS
        Get AD group for dfs resource
    .DESCRIPTION
        Get AD group for dfs resource
    #>
    PARAM ([string]$group_name_pattern)
    
    try {
        $group_object = Get-ADGroup -Properties Name, Description, distinguishedName $group_name_pattern
    }
    catch {
        $error_string += '|ERROR: when performing search security group (' + $group_name_pattern + ') in AD'
        $group_object = @{'Name'='None'; 'Description'='None'; 'distinguishedName'='None'}
    }
    if (!$group_object) {
        $error_string += '|Security group (' + $group_name_pattern + ') not found in AD'
        $group_object = @{'Name'='None'; 'Description'='None'; 'distinguishedName'='None'}
    }
    Return @{'GroupObject' = $group_object; 'Error' = $error_str}
}

Function Check-ResourceADGroupDescription {
    <#
    .SYNOPSIS
        Verifies the value of the security group description field in AD
    .DESCRIPTION
        Verifies the value of the security group description field in AD.
        The value must match:
            <Resource expiration date in format YYYY.MM.DD>|<OwnerFamily OwnerInitials>[|AnyText].
        Example - 2020.12.31|Petrov P.P.|Any text
    #>
    PARAM ([string]$group_description)
    
    $description_string = @('None'; 'None')
    if ($group_description -ne 'None') {
        if ($group_description -ne '') { # If the description field is not empty
            if ($group_description -match $group_description_pattern) {
                $error_str = ''
                $description_string = ($group_description -Split '\|').Trim()
            }
            else {
                $error_str = '|Security group description does not match pattern <YYYY.MM.DD|Familiya I.O.|[detail text]>'
            }
        }
        else {
            $error_str = '|Security group description field is empty'
        }
    }
    Return @{'GroupDescription' = $description_string; 'Error' = $error_str}
}

Function Check-ResourceADUserOwner {
    <#
    .SYNOPSIS
        Checks if the user account specified in the security group description field exists.
    .DESCRIPTION
        Checks if the user account specified in the security group description field exists.
    #>
    PARAM ([string]$group_description, [object]$all_users)
    
    if ($group_description -ne 'None') {
        $owner_string = $group_description -Split ' '
        $owner_last_name = $owner_string[0]
        $owner_firstname_symbol = ($owner_string[1] -Split '.')[0]
        $owner_middlename_symbol = ($owner_string[1] -Split '.')[1]
        $user_display_name_pattern = '^' + $owner_last_name + '[\s]' + $owner_firstname_symbol + '[à-ÿ]{0,}[\s]' + $owner_middlename_symbol + '[à-ÿ]{0,}'
        ForEach ($owner_ad_user in $all_users) {
            if ($owner_ad_user.displayName -match $user_display_name_pattern) {
                $error_string = ''
                $owner_sAMAccountName = $owner_ad_user.sAMAccountName
                }
        }
        if (!$owner_sAMAccountName) {
            $error_string = '|No user account found'
            $owner_sAMAccountName = 'None'
        }
    }
    Return @{'ADUser' = $owner_sAMAccountName; 'Error' = $error_string}
}

Function Check-ResourceDeadline {
    <#
    .SYNOPSIS
        Checking the expiration of a resource
    .DESCRIPTION
        Checking the expiration of a resource. The expiration date of the resource must be indicated in the security group description field.
    #>
    PARAM ([string]$deadline)
    
    $status_deadline = 'None'
    if ($deadline -ne 'None') {
        $deadline = [DateTime]::ParseExact($deadline,'yyyy.MM.dd',$null)
        $current_date = Get-Date
        if ($current_date.AddDays(-60) -gt $deadline) {
            $status_deadline = $message_deadline_60
        }
        elseif ($current_date.AddDays(-30) -gt $deadline) {
            $status_deadline = $message_deadline_30
        }
        elseif ($current_date -gt $deadline) {
            $status_deadline = $message_deadline
        }
        else {
            $status_deadline = 'OK'
        }
    }

    Return($status_deadline)
}