#!/bin/bash 
######################### 
# S.CAPS For NRB Sep2021 
######################### 

OU=kafka
ORG=myorg


if [ "$1" == "" ]; then 
        echo "Please add a username as argument." 
        echo "Example:" 
        echo "$0 myusername" 
        exit 1 
fi 

pwdldap_username=$1 

prompt="Please enter your new ldap password: " 
read -p "$prompt" -s CLEARTXTPWD 
echo -e "\n" 
prompt="Please confirm your new ldap password: " 
read -p "$prompt" -s CLEARTXTPWD2 

echo -e "\n" 
if [ "$CLEARTXTPWD" != "$CLEARTXTPWD2" ]; then 
        echo "The passwords do not match, exiting... !" 
        exit 2 
fi 

if [ "$CLEARTXTPWD" == "" ]; then 
        echo "Password empty exiting..." 
        exit 2 
fi 

FILENAME=`mktemp` 
echo -n "$CLEARTXTPWD" > $FILENAME 
PASSWD=`slappasswd -o module-load=pw-sha2 -h '{SSHA512}' -T $FILENAME` 

rm -f $FILENAME   
CLEARTXTPWD="" 
CLEARTXTPWD2="" 

FILENAME=`mktemp`   
cat <<EOF> ${FILENAME}
dn: uid=${pwdldap_username},ou=People,ou=${OU},o=${ORG}
changetype: modify
replace: userPassword
userPassword: ${PASSWD}
EOF

PASSWD="" 
  
ldapmodify -Y EXTERNAL -H ldapi:/// -f $FILENAME 

rm -f $FILENAME  

# EOF
