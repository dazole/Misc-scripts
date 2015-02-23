 This script mimics the functionality of Vintella's vas command:
 vastool user checkaccess $accountname

 It will check the following:
 Is $accountname a valid Unix-enabled account
 Is the account disabled
 Does $accountname have access to the server via any entry in 
 /etc/security/access.conf

 Requirements:  pam_ldap pam_access (/etc/security/access.conf)

 Only tested with AD and RHEL6
