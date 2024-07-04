#!/bin/bash

# Log file and password file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Ensure the password file exists and set proper permissions
init_password_file() {
    if [ ! -d "/var/secure" ]; then
        mkdir /var/secure
    fi
    touch $PASSWORD_FILE
    chmod 600 $PASSWORD_FILE
}

# Check if the script is run with a file argument
if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

# Read the input file
if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found!"
    exit 1
fi

# Initialize the password file
init_password_file

# Process each line in the file
while IFS=';' read -r username groups; do
    username=$(echo $username | xargs) # Trim whitespace

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        log_message "User '$username' already exists."
        continue
    fi

    # Create the user and personal group
    useradd -m -s /bin/bash "$username"
    if [ $? -eq 0 ]; then
        log_message "User '$username' created successfully."
    else
        log_message "Error creating user '$username'."
        continue
    fi

    # Create groups and add the user to them
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs) # Trim whitespace
        if [ ! -z "$group" ]; then
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                log_message "Group '$group' created."
            fi
            usermod -aG "$group" "$username"
            log_message "User '$username' added to group '$group'."
        fi
    done

    # Generate a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd

    # Log the password securely
    echo "$username,$password" >> $PASSWORD_FILE
    log_message "Password for '$username' set and stored securely."

done < "$1"

# Set proper permissions for the log file
chmod 640 $LOG_FILE
chown root:root $LOG_FILE

log_message "User creation process completed."

exit 0
