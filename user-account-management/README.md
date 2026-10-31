# Bulk User Account Management

A Bash script that creates Linux user accounts in bulk from a CSV file. For each
row it creates the account and home directory, assigns a randomly generated
password, and expires that password immediately so the user must choose their
own at first login.

Script: [`user.sh`](user.sh) · Input format: [`employee.csv.example`](employee.csv.example)

---

## How it works

```
employee.csv                    username,Full Name
      │
      │  while IFS=, read
      ▼
for each row:
      openssl rand -base64 12   generate a password nobody has seen
      useradd -m -c             create the account and home directory
      chpasswd                  set the password without a prompt
      chage -d 0                expire it, forcing a change at first login
      │
      ▼
out.txt                         private audit record (mode 600)
```

## Input format

Two columns, no header:

```csv
username,Full Name
```

## The three commands that do the work

| Command | Role |
|---|---|
| `useradd -m -c "$full_name" "$username"` | Creates the account, builds the home directory from `/etc/skel`, and writes the full name into the GECOS comment field |
| `echo "$username:$password" \| chpasswd` | Sets the password without an interactive prompt. `passwd` is built for humans and cannot be scripted; `chpasswd` reads `user:password` pairs from stdin |
| `chage -d 0 "$username"` | Sets the last password change to day zero of the Unix epoch, so the system treats the password as long expired and forces a change before the user reaches a shell |

## Design points

Two guards before any change. The script exits if it is not running as root,
and exits if the CSV file is missing. Both write to stderr, so error output can
be separated from normal output when the script is piped or scheduled.

`|| [ -n "$username" ]` on the read loop. `read` returns non-zero on the
final line when the file has no trailing newline, which would silently skip the
last user. This condition processes that row anyway.

Random passwords generated per user. `openssl rand -base64 12` produces a
value that exists nowhere until the moment it is created, so no shared or
guessable default is ever in use.

`umask 077` before the loop. `out.txt` holds every password in clear text.
With default permissions (644) any user on the system could read it. Setting the
umask first means the file is created mode 600, readable only by its owner.

Column order matches the input file. `out.txt` is written as
`username,full_name,password`, the same order as `employee.csv`, so anything
reading it later cannot pair the wrong name with the wrong login.

## Known limitation

`useradd` is not idempotent. Running the script twice against the same CSV fails
on `useradd` with "user already exists" but then continues to `chpasswd`, which
succeeds and silently replaces that user's password with one they have never
seen, locking them out. An existence check is needed before running this against
a system that already has accounts.

## Security notes

- `out.txt` contains live credentials. Distribute the passwords, then destroy it
  with `shred -u out.txt`. Because every password expires at first login, its
  value to an attacker ends once users have actually logged in.
- The password is passed through the shell. `echo` is a shell builtin, so it does
  not appear in the process list, but running the script with `bash -x` would
  print every password to the terminal. Never trace this script on a real system.
- Forced password change works cleanly for console and password-based SSH logins.
  A user connecting with an SSH key may be dropped with a bare "password expired"
  message depending on the SSH configuration, so this should be tested on one
  account before being applied to fifty.

## Verification

| Check | Command | Result |
|---|---|---|
| Root guard works | `./user.sh` as a normal user | Refuses, exit code 1 |
| Accounts created | `sudo ./user.sh` | One summary block per user |
| Audit file is private | `sudo ls -l out.txt` | `-rw-------` owner only |
| Home directory exists | `su - <user>` then `pwd` | `/home/<user>` |
| Identity is correct | `whoami` and `id` | Correct username, UID and GID |
| Password change is forced | `su - <user>` | "You are required to change your password immediately" |
| Expiry cleared after change | `sudo chage -l <user>` | Last password change shows a real date instead of the epoch |

## Usage

```bash
# 1. prepare the input file
cp employee.csv.example employee.csv
# edit it with your own users

# 2. make the script executable
chmod +x user.sh

# 3. run it with privilege
sudo ./user.sh

# 4. distribute the credentials, then destroy the audit file
sudo shred -u out.txt
```

Test on a disposable virtual machine first. This script creates real accounts
and changes real passwords.
