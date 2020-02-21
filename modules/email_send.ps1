Function Send-Email {
    <#
    .SYNOPSIS
        Sends email messages
    .DESCRIPTION
        Sends email messages
    #>
    PARAM ([String]$email_recepient, [String]$email_subject, [String]$email_message, [String]$email_attachment_link)

    if ($email_recepient -ne 'None') {
        $encoding = [System.Text.Encoding]::UTF8
        $smtp = new-object Net.Mail.SmtpClient($smtp_server)
        $mail_message = new-object Net.Mail.MailMessage
        if ($email_attachment_link -ne 'None') {
            $email_attachment = new-object Net.Mail.Attachment($email_attachment_link)
            $mail_message.Attachments.Add($email_attachment)
        }
        $mail_message.BodyEncoding = $encoding
        $mail_message.Body = $email_message
        $mail_message.IsBodyHtml = $true
        $mail_message.SubjectEncoding = $encoding
        $mail_message.Subject = $email_subject
        $mail_message.To.Add($email_recepient)
        $mail_message.From = $email_from
        $mail_message.Priority = $email_priority
        
        $smtp.Send($mail_message)
        $error_email_send = 'OK'
    }
    else {$error_email_send = 'Message recipient missing'}
    
    Return @{'Error' = $error_email_send}
}