Import-Module ActiveDirectory
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\List-Dfsn.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\dfs_functions.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\modules\Function-Write-Log.ps1
Import-Module C:\ScriptDevelopment\DFS_Audit\settings.ps1

# Declare variables
$report = @()

$resources = (List-Dfsn -Path $dfs_namespace -IncludeSMBShares -SkipAccessErrors | Where-Object {$_.Path -like $dfs_path -and $_.ShareName -notin $excl_resource_names})
ForEach ($resource in $resources) {
    $share_server = $resource.ShareServer
    $share_name = $resource.ShareName
    $path = $resource.Path
    $target_path = $resource.TargetPath
    $resource_local_path = $resource.ShareLocalPath + ($resource.TargetPath -replace '\\\\' + $resource.ShareServer + '\\' + $resource.ShareName)
    $error_string = ''
    $row = '' | Select-Object resource_link, resource_owner, resource_expiration_date, resource_quota, resource_quota_use
    
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

    $row.resource_link = $path
    $row.resource_owner = $group_description[1]
    $row.resource_expiration_date = $group_description[0]
    
    # Resource quota use
    try {
        $quota_value = Get-FSRMQuota -CimSession $share_server -Path $resource_local_path -ErrorAction Stop
        $row.resource_quota = [math]::Round($quota_value.Size / 1073741824)
        $row.resource_quota_use = [math]::Round($quota_value.Usage / 1073741824)
    }
    catch {
        $row.resource_quota = 'Empty'
        $row.resource_quota_use = 'Empty'
    }

    $report += $row
}
  
if ($report) {
    $report | Sort-Object resource_link | Export-Csv -Delimiter ';' -Path $report_dfs_resource_list_link -Encoding UTF8
    #$report | Sort Адрес_ресурса | Export-Csv -Delimiter ';' -Path $report_link_share -Encoding UTF8
}