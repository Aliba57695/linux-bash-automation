# Linux and Bash Automation

Two Bash automation projects built and run on an Amazon Linux EC2 instance:
a scheduled backup that replicates to Amazon S3, and bulk user provisioning
from a CSV file.

| Project | What it does | Key skills |
|---|---|---|
| [s3-backup-automation](s3-backup-automation/) | Compresses a directory, logs the run, uploads the archive to S3, runs on a schedule | `tar` · `cron` · AWS CLI · IAM · S3 · logging · exit codes |
| [user-account-management](user-account-management/) | Creates user accounts in bulk from CSV, assigns random passwords, forces a password change at first login | `useradd` · `chpasswd` · `chage` · `openssl` · `umask` · CSV parsing |

Both scripts were written, run and verified on a live Linux server rather than
tested only on paper.

---

## Why these two

They cover the two tasks a Linux or cloud support engineer automates most often:

- Protecting data on a schedule, with the result stored off the server
- Onboarding users safely, without reusing passwords or leaving credentials
  readable on disk

---

## Environment

| | |
|---|---|
| Operating system | Amazon Linux (RHEL family) on EC2 |
| Shell | Bash |
| AWS access | IAM role attached to the instance, with access keys tested as the alternative |
| Tools | AWS CLI v2, `tar`, `cron`, `openssl` |

## Repository structure

```
.
├── README.md
├── s3-backup-automation/
│   ├── README.md
│   └── backup-script.sh
└── user-account-management/
    ├── README.md
    ├── user.sh
    └── employee.csv.example
```
