#!/usr/bin/env bash
# Openssl encrypt/decrypt examples
# Encrypt file to file
#openssl enc -aes-256-cbc -salt -in file.txt -out file.txt.enc
# Decrypt file to stdout
#openssl enc -aes-256-cbc -d -salt -in file.txt.enc
# Decrypt file to file
#openssl enc -aes-256-cbc -d -salt -in file.txt.enc -out file.txt

# Init
TOKENFILES_DIR="$( dirname ${0} )/tokenfiles"
PASSWORD_DIR="$( dirname ${0} )/keys"
TOKENFILES_DIR_MODE="$( ls -ld ${TOKENFILES_DIR} | awk '{print $1}'| sed 's/.//' )"
U_MODE="$( awk  -F '' '{print $1 $2 $3}' <<< "$TOKENFILES_DIR_MODE" )"
G_MODE="$( awk  -F '' '{print $4 $5 $6}' <<< "$TOKENFILES_DIR_MODE" )"
A_MODE="$( awk  -F '' '{print $7 $8 $9}' <<< "$TOKENFILES_DIR_MODE" )"

if [ "$( echo $G_MODE | egrep 'r|w|x' )" -o "$( echo $A_MODE | egrep 'r|w|x' )" ]; then
    echo "Perms on [${TOKENFILES_DIR}] are too permissive. Try 'chmod 700 ${TOKENFILES_DIR}' first"
    # exit 1
fi

PASSWORD_DIR_MODE="$( ls -ld ${PASSWORD_DIR} | awk '{print $1}'| sed 's/.//' )"
U_MODE="$( awk  -F '' '{print $1 $2 $3}' <<< "$PASSWORD_DIR_MODE" )"
G_MODE="$( awk  -F '' '{print $4 $5 $6}' <<< "$PASSWORD_DIR_MODE" )"
A_MODE="$( awk  -F '' '{print $7 $8 $9}' <<< "$PASSWORD_DIR_MODE" )"

if [ "$( echo $G_MODE | egrep 'r|w|x' )" -o "$( echo $A_MODE | egrep 'r|w|x' )" ]; then
    echo "Perms on [${PASSWORD_DIR}] are too permissive. Try 'chmod 700 ${PASSWORD_DIR}' first"
    # exit 1
fi


token="$1"
if [ -z "$token" ]; then echo "Need token filename"; exit 1; fi

password="$2"
if [ -z "$password" ]; then password="$token"; fi


# Returns the token
function get_decrypted_token_from_file {
    read -s -r -p "Password for secret(token): " PASSWORD
    echo $PASSWORD | openssl enc -aes-256-cbc -d -salt -pass stdin -in ${TOKENFILES_DIR}/${token}.enc
}

function get_plaintext_token_from_file {
    cat ${TOKENFILES_DIR}/$token
}

if [[ -f "${TOKENFILES_DIR}/${token}.enc" ]]; then
    TOKEN=$( get_decrypted_token_from_file $token )
elif [[ -f "${TOKENFILES_DIR}/${token}" ]]; then
    TOKEN=$( get_plaintext_token_from_file $token )
else
    echo "ERROR: Key file [${TOKENFILES_DIR}/$token] doesn't exist"
    # exit 1
fi

#TOKEN=$( get_decrypted_token_from_file $token )
#echo
D=0
D="$( date  +%S )"
if [ $D -gt 30 ] ; then D=$( echo "$D - 30"| bc ); fi
if [ $D -lt 0 ] ; then D="00"; fi

if [[ -f "${TOKENFILES_DIR}/${password}.enc" ]]; then
    read -s -r -p "Password for Savio cluster: " PASSWORD
    CODE=$( echo $PASSWORD | openssl enc -aes-256-cbc -d -salt -pass stdin -in ${PASSWORD_DIR}/${password}.enc )
elif [[ -f "${TOKENFILES_DIR}/${password}" ]]; then
    CODE=$( cat ${PASSWORD_DIR}/${password} )
else
    echo "ERROR: Key file [${PASSWORD_DIR}/$password] doesn't exist"
    # exit 1
fi

X=$( oathtool --totp -b "$TOKEN" )
USERNAME=$(echo $CODE | awk '{print $1}')
PLAINCODE=$(echo $CODE | awk '{print $2}')
NODE=$(echo $CODE | awk '{print $3}')
if [[ -z $NODE ]]; then NODE="hpc"; fi

# mount home
saviokey=$PLAINCODE$X
saviopath="$USERNAME@dtn.brc.berkeley.edu:/global/home/users/$USERNAME/"
if mountpoint -q ~/savio/home; then
    sudo umount -f ~/savio/home
    echo "umount ~/savio/home"
fi
sudo sshfs -o allow_other,password_stdin,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 $saviopath ~/savio/home <<< "$saviokey"


# mount scratch
Y=$( oathtool --totp -b "$TOKEN" )
attempt=1
marks=( '/' '-' '\' '|' )
while [ "$Y" == "$X" ];
do
    count=10
    while [[ $count -gt 0 ]]; do
     printf '%s\r' "Attempt $attempt: wait for a new OTP in $(printf %02d $count) seconds ${marks[i++ % ${#marks[@]}]}"
     count=$((count-1))
     sleep 1
    done
    Y=$( oathtool --totp -b "$TOKEN" )
    attempt=$((attempt+1))
done
saviokey=$PLAINCODE$Y
saviopath="$USERNAME@dtn.brc.berkeley.edu:/global/scratch/$USERNAME/"
if mountpoint -q ~/savio/scratch; then
    sudo umount -f ~/savio/scratch
    echo "umount ~/savio/scratch"
fi
sudo sshfs -o allow_other,password_stdin,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 $saviopath ~/savio/scratch <<< "$saviokey"
