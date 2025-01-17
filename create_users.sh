#!/bin/bash

# checks if the script is run as root, since root privilege is required 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Log file
LOG_FILE="/var/log/user_management.log"

PASSWORD_FILE="/var/secure/user_passwords.csv"

# ensuring the log and password files exists
mkdir -p /var/secure
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# this function logs an action
log() {
    echo "$(date +"%Y-%m-%d %T") - $1" | tee -a $LOG_FILE
}

# random password for users
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# input file
INPUT_FILE=$1
if [[ ! -f $INPUT_FILE ]]; then
    log "Input file does not exist: $INPUT_FILE"
    exit 1
fi

while IFS=';' read -r username groups; do
    # Remove  whitespace
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)

    if id "$username" &>/dev/null; then
        log "User $username already exists. Skipping..."
        continue
    fi

    # user and personal group
    useradd -m -s /bin/bash "$username"
    log "Created user $username with home directory /home/$username"

    # home directory permissions
    chown "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log "Set permissions for /home/$username"

    # create and add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)  # Remove whitespace
        if [[ ! $(getent group $group) ]]; then
            groupadd $group
            log "Created group $group"
        fi
        usermod -aG "$group" "$username"
        log "Added user $username to group $group"
    done

    # random password
    password=$(generate_password)
    echo "$username,$password" >> $PASSWORD_FILE
    echo "$username:$password" | chpasswd
    log "Set password for user $username"

done < "$INPUT_FILE"

log "User creation process completed."

exit 0
