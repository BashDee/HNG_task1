# HNG_task1
HNG 11 task 1 exercise for DevOps track



As a SysOps engineer, managing users and their permissions efficiently is a critical part of ensuring smooth operations. In this article, we'll explore a Bash script designed to automate the creation of users and groups on an Ubuntu system. This script reads from a text file containing usernames and groups, generates random passwords, and logs all actions performed.
Script Overview

The create_users.sh script performs the following tasks:

    Reads a text file containing usernames and their associated groups.
    Creates users and groups as specified.
    Sets up home directories with appropriate permissions.
    Generates random passwords for the users.
    Logs all actions to /var/log/user_management.log.
    Stores passwords to /var/secure/user_passwords.csv.

Here's the concise breakdown of each step on how the script is being executed.

Step 1: Checking for Root Privileges

The script must be run as root to perform user management tasks. The below code check for root privileges at the beginning to ensure the scrip is executed successfully

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

Step 2: Setting Up Log and Password Files

We create and set permissions for the log and password files ensuring only sudo user can view the password.csv file

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
mkdir -p /var/secure
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

Setting chmod 600 on users_passwords.csv restricts other users except the sudo user from reading/writing to the file. This is very important for the security of other users.

Step 3: Reading the Input File

The following lines read the input file specified as the first argument. If the file does not exist, logs an error and exit

INPUT_FILE=$1
if [[ ! -f $INPUT_FILE ]]; then
    log "Input file does not exist: $INPUT_FILE"
    exit 1
fi

Step 4: Creating Users and Groups

For each line in the input file, the script extracts the username and groups, creates the user and their personal group, sets up home directory permissions, and adds the user to additional groups. A while loop is used so as to successfully exhaust all entries in the input file

while IFS=';' read -r username groups; do
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)

    if id "$username" &>/dev/null; then
        log "User $username already exists. Skipping..."
        continue
    fi

    useradd -m -s /bin/bash "$username"
    log "Created user $username with home directory /home/$username"
    chown "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log "Set permissions for /home/$username"

    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        if [[ ! $(getent group $group) ]]; then
            groupadd $group
            log "Created group $group"
        fi
        usermod -aG "$group" "$username"
        log "Added user $username to group $group"
    done

Step 5: Generating and Storing Passwords

The script generates a random password for each user, updates the user's password, and stores it 

generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

password=$(generate_password)
echo "$username,$password" >> $PASSWORD_FILE
echo "$username:$password" | chpasswd
log "Set password for user $username"

Conclusion

This script provides a comprehensive solution for managing user accounts and groups efficiently, ensuring secure storage of user credentials and detailed logging of all actions performed.

This script was given as a task for HNG Internship Program. For more information about HNG or HNG Internship program, check out these links:

HNG Internship | HNG Hire

This script automates the tedious task of user management, allowing SysOps engineers to focus on more critical tasks while ensuring that user accounts are managed securely and efficiently.
