 This script enables unix access for an AD account:

 It will do the following:
 * Check if the account is already Unix-enabled (does the account have a UID?)
 If not:
 * Generate a UID based on the Windows SID
 * Edit the UID, GID, HomeDir, LoginShell, and Gecos fields
 * Some part of the above make the AD account "Unix-enabled":

 ##Requirements:  
 * Powershell 
 * ActiveDirectory powershell module
