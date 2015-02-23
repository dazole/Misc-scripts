#!/bin/bash

# This script mimics the functionality of Vintella's vas command:
# vastool user checkaccess $accountname
#
# It will check the following:
# Is $accountname a valid Unix-enabled account
# Is the account disabled
# Does $accountname have access to the server via any entry in 
# /etc/security/access.conf

# Requirements:  pam_ldap pam_access (/etc/security/access.conf)
# Only tested with AD and RHEL6

AUTHOR="David Patterson <david@damnetwork.net"
VERSION="20150222"
BINDDN=""
BINDPW=""
#BASE="OU=Something,OU=Somethingelse,dc=company,dc=com"
BASE=""
HOST=""
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
NORMAL=$(tput sgr0)
ACCOUNT=$1
# Function to print the help screen.
print_help () {
  echo
  echo "Usage:  $1 <account_name>"
  echo "        $1 [-h|--help]"
  echo "        $1 [-v|--version]"
  echo
  echo "   ex.  ${BLUE}$1 someaccount${NORMAL}"
  exit 1
}

# Function to check for root priviledges.
check_root () {
  if [[ `/usr/bin/id | awk -F= '{print $2}' | awk -F"(" '{print $1}' 2>/dev/null` -ne 0 ]]; then
    echo 
    printf "${RED}*** You must have root priviledges to run this program. ***${NORMAL}%s\n"
    echo
    exit 2
  fi
}

# If the variable DEBUG is set, then turn on tracing.
# http://www.research.att.com/lists/ast-users/2003/05/msg00009.html
if [ $DEBUG ]; then
  # This will turn on the ksh xtrace option for mainline code
  set -x
  
  # This will turn on the ksh xtrace option for all functions
  typeset +f |
  while read F junk
  do
    typeset -ft $F
  done
  unset F junk
fi

# Process arguments.
while [[ $1 = -* ]]; do
  case $1 in
    -h|--help)
      print_help "$(basename $0)"
      ;;
    -v|--version)
      printf "%s\n"
      printf "%s\tLDAP user access check%s\n"
      printf "%s\tVersion: $VERSION%s\n"
      printf "%s\tWritten by: $AUTHOR%s\n"
      printf "%s\n"
      exit 0
      ;;
    *)
      print_help "$(basename $0)"
      ;;
  esac
  shift
done

# Check to see if we have no parameters.
if [[ ! $# -eq 1 ]]; then print_help "$(basename $0)"; fi

check_unix () {

echo
printf "%s\t Checking to see if ${ACCOUNT} is Unix Enabled in AD:%s\n"

# Check to see if the account is unix enabled
UNIX_ACCOUNT=`ldapsearch -D ${BINDDN} -w ${BINDPW} -x -b "${BASE}" -h ${HOST} "(&(samaccountname=${ACCOUNT})(objectCategory=Person)(objectClass=User)(uidNumber=*))" samaccountname | grep sAMAccountName | awk '{ print $2 }'`

if [[ ZZ${UNIX_ACCOUNT} = "ZZ" ]]; then
  printf "%s\t ${RED}${ACCOUNT} is not Unix Enabled in AD.${NORMAL}%s\n"
  echo
else
  printf "%s\t ${GREEN}Looks good!  ${ACCOUNT} is Unix Enabled in AD!${NORMAL}%s\n"
  echo
fi

}

check_group () {

printf "%s\t Let's check the AD Group access.%s\n"

# Get all the AD groups the account is a member of
AD_GROUPS=`ldapsearch -D ${BINDDN} -w ${BINDPW} -x -b "${BASE}" -h ${HOST} "(samaccountname=${ACCOUNT})" memberof | grep memberOf | awk -F, '{ print $1 }' | cut -c 14-`

# Get all the groups that are allowed login access
ALLOWED=`grep "^+" /etc/security/access.conf | awk -F":" '{ print $2 }'`

# Then loop through each and see if it matches with the groups the account 
# is a member of.
declare -a ALLOW_CHECK=();
for i in `echo "${ALLOWED}"`;
do
  for result in `echo "${AD_GROUPS}"`
  do
    if [[ "${i}" = "${result}" ]]; then
     ALLOW_CHECK=("${ALLOW_CHECK[@]}" "${i},")
    fi
  done
done
if [[ ${ALLOW_CHECK}ZZ = "ZZ" ]]; then
  printf "%s\t ${RED}${ACCOUNT} does not have access to this server via any AD groups.${NORMAL}%s\n"
  echo
else
  printf "%s\t ${GREEN}${ACCOUNT} is allowed access via AD Groups ${BLUE}[ ${ALLOW_CHECK[*]} ].${NORMAL}%s\n"
  echo
fi
}

# Check if the account is disabled
check_disabled () {

printf "%s\t Lets check if the account is disabled in AD:%s\n"

DISABLED=`ldapsearch -D ${BINDDN} -w ${BINDPW} -x -b "${BASE}" -h ${HOST} "(&(samaccountname=${ACCOUNT})(UserAccountControl:1.2.840.113556.1.4.803:=2))" cn | grep "cn:" | awk -F":" '{ print $2 }'`

if [[ ${DISABLED}ZZ = "ZZ" ]]; then
  printf "%s\t ${GREEN}Woohoo!  ${ACCOUNT} is not Disabled!${NORMAL}%s\n"
  echo
else
  printf "%s\t ${RED}${DISABLED}'s account is currently disabled${NORMAL}%s\n"
  echo
fi

}
#echo ${EXPIRED}
check_root

check_unix
check_disabled
check_group

#Make sure we leave them with normal text
printf "${NORMAL}"
