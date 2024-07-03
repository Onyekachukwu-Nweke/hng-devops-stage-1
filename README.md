## HNG-DevOps-Stage-1 Task: User Creation and Management Script

### Introduction

This repository contains a bash script, `create_users.sh`, designed to automate the creation and management of user accounts on a Linux system. The script reads a list of usernames and their respective groups from a text file, creates the users and groups, assigns appropriate permissions, generates random passwords for each user, and logs all actions. Additionally, it stores the generated passwords securely.

### Features

- **Automated User Creation**: Creates user accounts and assigns them to specified groups.
- **Password Generation**: Generates random passwords for each user.
- **Logging**: Logs all actions to `/var/log/user_management.log`.
- **Secure Password Storage**: Stores user passwords securely in `/var/secure/user_passwords.csv`.

### Prerequisites

- **Linux System**: The script is intended to be run on a Linux system.
- **Root Privileges**: Root or sudo privileges are required to create users and groups.
- **Text File**: A text file containing usernames and group names in the format `username;group1,group2,...`.

### Usage

1. **Prepare the Input File**

    Create a text file (e.g., `users.txt`) with the following format:

    ```plaintext
    user1; sudo,dev,www-data
    user2; sudo
    user3; dev,www-data
    user4; staff,admin
    user5; sudo,www-data
    ```

2. **Run the Script**

    Execute the script by providing the input file as an argument:

    ```bash
    sudo bash create_users.sh users.txt
    ```

### Script Breakdown

Here are some key snippets from the `create_users.sh` script to understand its functionality:

#### Logging Function

```bash
# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}
```

The `log_message` function logs messages with timestamps to the specified log file.

#### Initialize Password File

```bash
# Ensure the password file exists and set proper permissions
init_password_file() {
    if [ ! -d "/var/secure" ]; then
        mkdir /var/secure
    fi
    touch $PASSWORD_FILE
    chmod 600 $PASSWORD_FILE
}
```

This function ensures the secure password file exists and sets appropriate permissions.

#### User and Group Creation

```bash
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
```

These snippets handle the creation of user accounts and their assignment to specified groups.

#### Password Generation and Storage

```bash
# Generate a random password
password=$(openssl rand -base64 12)
echo "$username:$password" | chpasswd

# Log the password securely
echo "$username,$password" >> $PASSWORD_FILE
log_message "Password for '$username' set and stored securely."
```

This part of the script generates a random password for each user and stores it securely.

### Conclusion

This script automates the process of user account creation and management, ensuring security and consistency. By logging all actions and securely storing passwords, it provides a robust solution for managing user accounts in a Linux environment.
