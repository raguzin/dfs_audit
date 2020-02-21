Import-Module ActiveDirectory
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\List-Dfsn.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\email_send.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\dfs_functions.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\Function-Write-Log.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\settings.ps1


# Declare variables
$report_error = @()
$report_audit = @()

$all_users = Get-ADUser -Filter * -Properties Enabled,employeeID,title,displayName, sAMAccountName, givenName, middleName -SearchBase $search_base_users | where {($_.Enabled -eq $true) -and ($_.employeeID -notlike "")}

$resources = (List-Dfsn -Path $dfs_namespace -SkipAccessErrors | Where-Object {$_.Path -like $dfs_path -and $_.ShareName -notin $excl_resource_names})
ForEach ($resource in $resources) {
    $share_server = $resource.ShareServer
    $share_name = $resource.ShareName
    $path = $resource.Path
    $target_path = $resource.TargetPath
    $error_string = ''
    
    # Get a security group name pattern
    $temp = @()
    $temp = Get-ResourceADGroupNamePattern $share_server $share_name $target_path
    $group_name_pattern = $temp['GroupPattern']
    $error_string += $temp['Error']

    # Get security group from AD
    $temp = @()
    $temp = Get-ResourceADGroup $group_name_pattern
    $group_object = $temp['GroupObject']
    $error_string += $temp['Error']

    # Check security group description field
    $temp = @()
    $temp = Check-ResourceADGroupDescription $group_object.Description
    $group_description = $temp['GroupDescription']
    $error_string += $temp['Error']

    # Check the owner account specified in the security group description field
    $temp = @()
    $temp = Check-ResourceADUserOwner $group_description[1] $all_users
    $owner_ad_user = $temp['ADUser']
    $error_string += $temp['Error']

    # Checking the expiration of a resource
    $status_deadline = Check-ResourceDeadline $group_description[0]
    if ($status_deadline -ne 'OK') {
        $error_string += $status_deadline
    }
    
    # Output
    if ($error_string -ne '') {
        $row_error = "" | select ResourcePath, TargetPath, ResourceGroupRW, GroupRWDescription, ResourceOwnerADUser, ResourceDeadline, Status
        $row_error.ResourcePath = $path
        $row_error.TargetPath = $target_path
        $row_error.ResourceGroupRW = $group_object.Name
        $row_error.GroupRWDescription = $group_object.Description
        $row_error.ResourceOwnerADUser = $owner_ad_user
        $row_error.ResourceDeadline = $status_deadline
        $row_error.Status = $error_string
        $report_error += $row_error
    }
    $row_audit = "" | select ResourcePath, TargetPath, ResourceGroupRW, GroupRWDescription, ResourceOwnerADUser, ResourceDeadline, Status
    $row_audit.ResourcePath = $path
    $row_audit.TargetPath = $target_path
    $row_audit.ResourceGroupRW = $group_object.Name
    $row_audit.GroupRWDescription = $group_object.Description
    $row_audit.ResourceOwnerADUser = $owner_ad_user
    $row_audit.ResourceDeadline = $status_deadline
    $row_audit.Status = $error_string
    $report_audit += $row_audit
    
    # Sending email to file resource owners
    if ($status_deadline -ne 'OK' -and $owner_ad_user -ne 'None' -and $owner_ad_user -notin $excl_recepient_email) {
        $email_recepient = 'RaguzinAS@gtp.transneft.ru' # $owner_ad_user + '@' + $domain_name
        $email_subject = $status_deadline
        $deadline_str = $group_description[0]
        # email message text
        $email_message = "
        Уважаемый(ая) $owner_ad_user,
        Вы являетесь владельцем файлового ресурса '$path'. Для ресурса наступил срок окончания его использования - $deadline_str. 
        Для продления срока использования файлового ресурса Вам необходимо оформить СЗ в СЭД по шаблону 'ГТП СЗ УИТ создание файлового ресурса: Заявка на доступ к ИР'.
        Если ресурс более неактуален, просьба сообщить об этом на адрес $email_recepient_administrator 
        В случае отсутствия СЗ спустя 30 дней с указанной даты доступ к файловому ресурсу будет прекращен, а спустя 60 дней - ресурс будет удален с сервера!
        "
        $email_attachment_link = 'None'
        
        $temp = @()
        $temp = Send-Email $email_recepient $email_subject $email_message $email_attachment_link
        $error_email_send = $temp['Error']

        if ($error_email_send -eq 'OK') {
            Write-Log -Message "Email about the expiration of the resource $path was sent to $email_recepient" -Path $logfile_dfs_resource_error_link -Level 'Warn'
        }
        else {
            Write-Log -Message "Failed to send an email about the expiration of the resource $path to the address $email_recepient" -Path $logfile_dfs_resource_error_link -Level 'Error'
        }
    }
}


if ($report_audit) {
    $report_audit | Sort Path | Export-Csv -Delimiter ';' -Path $report_dfs_resource_audit_link -Encoding UTF8
}
# Sending email to administrators
if ($report_error) {
    $report_error | Sort Path | Export-Csv -Delimiter ';' -Path $report_dfs_resource_error_link -Encoding UTF8

    $email_attachment_link = $report_dfs_resource_error_link
    $temp = @()
    $temp = Send-Email $email_recepient_administrator $email_subject_errors_report $email_message_errors_report $email_attachment_link
    $error_email_send = $temp['Error']

    if ($error_email_send -eq 'OK') {
        Write-Log -Message "Email with invalid file resources report was sent to $email_recepient_administrator" -Path $logfile_dfs_resource_error_link 
    }
    else {
        Write-Log -Message "Failed to send report about invalid file resources to $email_recepient_administrator" -Path $logfile_dfs_resource_error_link -Level 'Error'
    }
}
else {
    $email_attachment_link = 'None'
    $temp = @()
    $temp = Send-Email $email_recepient_administrator $email_subject_ok_report $email_message_ok_report $email_attachment_link
    $error_email_send = $temp['Error']

    if ($error_email_send -eq 'OK') {
        Write-Log -Message "Email with file resources report was sent to $email_recepient_administrator" -Path $logfile_dfs_resource_error_link
    }
    else {
        Write-Log -Message "Failed to send report about file resources to $email_recepient_administrator" -Path $logfile_dfs_resource_error_link -Level 'Error'
    }
}

$email_attachment_link = $logfile_dfs_resource_error_link
$temp = @()
$temp = Send-Email $email_recepient_administrator $email_subject_log $email_message_log $email_attachment_link
$error_email_send = $temp['Error']

if ($error_email_send -ne 'OK') {
    Write-Log -Message "Failed to send report about expired file resources to $email_recepient_administrator" -Path $logfile_dfs_resource_error_link -Level 'Error'
}