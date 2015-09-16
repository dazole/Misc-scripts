param (
    [string]$username = $(throw "-username is required.")
)

Import-Module ActiveDirectory

# Variables to change
$SearchBase="DC=company,DC=com"
$Domain="YOUR_AD_DOMAIN"
$DefaultGID=""
$HomeDirPath="/home" # No trailing backslash
$LoginShell="/bin/bash"

# Check if the user is already unix enabled

$unix_enabled = Get-ADUser -Filter {(samaccountname -eq $username) -and (uidNumber -like "*")} -SearchBase $SearchBase -Properties:uidnumber

# Debug
#echo "unix_enabled = $unix_enabled"
#$unix_enabled.uidnumber

# We're pretty basic.  We only check to see if the account has a uidnumber assinged.  If so, we assume the account is already
# unix-enabled.  If not, we do the needful.
if ($unix_enabled.uidnumber) {
  echo ""
  Write-Host -Foregroundcolor Green "Already unix enabled"
  echo ""
  exit
} else {

  echo ""
  Write-Host -Foregroundcolor Red "Not unix enabled - I'll enable the account"
  echo ""

# Need info from this
  $new_user = Get-ADUser -Filter {(samaccountname -eq $username)} -SearchBase $SearchBase -Properties:*

  $objUser = New-Object System.Security.Principal.NTAccount($Domain, $username )
  $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
  $sid_array = $strSID.Value -split "-"
# The unix UID will be the last field of the SID, which should always be unique
  $new_uid = $sid_array[7]

  Set-ADUser -Identity $username -Replace @{gidnumber="$DefaultGID"} #Set Group ID
  Set-ADUser -Identity $username -Replace @{uidnumber="$new_uid"} #Set User ID
  Set-AdUser -Identity $username -Replace @{unixHomeDirectory="$HomeDirPath/$username"} #Set homedir
  Set-ADUser -Identity $username -Replace @{LoginShell="$LoginShell"}
  Set-ADUser -Identity $username -Replace @{gecos=$new_user.DisplayName} # set gecos
  exit
}
