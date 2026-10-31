#!/bin/bash
#
# Bulk-creates Linux user accounts from a CSV file. For each row it creates the
# account, assigns a random password, and expires that password so the user must
# set their own at first login. Credentials are written to a private audit file.

CSV_FILE="employee.csv"

# --- guard 1: must be root ---
if [ "$EUID" -ne 0 ]
then
        echo "This script must be run as root." >&2
        exit 1
fi

# --- guard 2: the input file must exist ---
if [ ! -f "$CSV_FILE" ]
then
        echo "CSV file not found: $CSV_FILE" >&2
        exit 1
fi

# --- keep the credential file private (owner read/write only) ---
umask 077

while IFS=, read -r username full_name || [ -n "$username" ]
do
        password=$(openssl rand -base64 12)

        useradd -m -c "$full_name" "$username"
        echo "$username:$password" | chpasswd
        chage -d 0 "$username"

        echo "User created:     $username"
        echo "Full name:        $full_name"
        echo "Random password:  $password"
        echo "_________________________________________"

        echo "$username,$full_name,$password" >> out.txt
done < "$CSV_FILE"

echo "All users have been created."
