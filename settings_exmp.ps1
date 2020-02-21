# CHANGE NAME TO SETTINGS.PS1

$domain_name = 'domain.corp'
$dfs_namespace = '\\domain.corp\root'
$dfs_path = '\\domain.corp\root\folder\*'
$search_base_users = "OU=<OU>,DC=domainDC=corp"

# Folder names excluded from the verification task
$excl_resource_names = @('folder1', 'folder2')

# Email excluded from mailing
$excl_recepient_email = @('Email Account')

# for function Get-ResourceADGroupNamePattern
$prefix = 'GP_'
$suffix = '_RW'

# for function Check-ResourceADGroupDescription 
$group_description_pattern = '^20[1-3][\d].[0-1][\d].[0-3][\d]\|[a-z]{1,} [a-z]{1}.[a-z]{0,}.'

# for function Check-ResourceDeadline
$message_deadline_60 = 'The resource has expired more than 60 days and must be deleted.'
$message_deadline_30 = 'The resource has expired more than 30 days and must be closed.'
$message_deadline = 'The resource has expired.'

# for function Send-Email
$email_from = "Form Email address"   
$smtp_server = "smtp_server.domain.corp"
$email_priority = "High"
$email_recepient_administrator = 'Administrator group'
$email_subject_errors_report = 'Invalid file resources report'
$email_message_errors_report =  "Administrator, correct errors in the description of file resources."
$email_subject_ok_report = 'File resources report'
$email_message_ok_report = 'All file resources are correct!'
$email_subject_log = 'Expired resources alerts log'
$email_message_log = 'Expired resources alerts log in attachement.'

# OUTPUT LINKS
$report_dfs_resource_list_link = 'output path csv-file' # Output file for dfs_list_resources_maker.ps1 2
$report_dfs_resource_error_link = 'output path csv-file' # Output file with errors for dfs_resources_verifier.ps1
$report_dfs_resource_audit_link = 'output path csv-file' # Output file with info for dfs_resources_verifier.ps1

# LOG LINKS
$current_date = Get-Date -Format yyyy-MM-dd
$logfile_dfs_resource_error_link = "output path_$current_date.log" # Log file for dfs_resources_verifier.ps1