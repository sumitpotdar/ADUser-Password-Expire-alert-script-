
###################################################################
##Script File Name		: Password-Expire-Alert.ps1
## Script Author		: Sumit Potdar
## script Description	: send email alert to end user to inform password expire days remaining,
## Note			: check all the input parameter according your environment
##################################################################################33



$smtpServer="<server IP or Hostname>"
$expireindays = 14
$from = "<From Email ID>"
$logging = "Enabled"
$logFile = "<Clog file path, should be in CSV>"
$testing = "Disabled"
$testRecipient = "<email id for testing>"
$date = Get-Date -format ddMMyyyy


if (($logging) -eq "Enabled")
{
    
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True")
    {
        
        New-Item $logfile -ItemType File
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn"
    }
} 


Import-Module ActiveDirectory
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge


foreach ($user in $users)
{
    $Name = (Get-ADUser $user | foreach { $_.Name})
    $emailaddress = $user.emailaddress
    $passwordSetDate = (get-aduser $user -properties * | foreach { $_.PasswordLastSet })
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)

    if (($PasswordPol) -ne $null)
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
  
    $expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
   
    $messageDays = $daystoexpire

    if (($messageDays) -ge "1")
    {
        $messageDays = "in " + "$daystoexpire" + " days"
    }
    else
    {
        $messageDays = "today."
    }

    
    $subject="Your password will expire $messageDays"
  
    
    $body ="
    Dear $name,
    <p> Your password will expire on $ExpiresOn.<br>
    <p> To change your password from your PC, press Ctrl+Alt+Delete and choose Change Password. If you are traveling, please ensure that you have connected to the VPN application before attempting to reset your password. For those of you who use your mobile devices for company email, please remember to change the email settings to reflect the new password.  <br>
    <p><br>If you have any questions contact the Service Desk at .<br>
    <p><br>Thanks, <br>
    </P>
    </P>"

   
   
    if (($testing) -eq "Enabled")
    {
        $emailaddress = $testRecipient
    }

   
    if (($emailaddress) -eq $null)
    {
        $emailaddress = $testRecipient    
    }

   
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
    {
         
        if (($logging) -eq "Enabled")
        {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson" 
        }
        
        Send-Mailmessage  -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High -smtpServer $smtpServer

    } #
    
} 