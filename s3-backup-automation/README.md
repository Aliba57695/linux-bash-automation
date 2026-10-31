# Scheduled Backup with Replication to Amazon S3

A Bash script that compresses a directory into a timestamped archive, records
every step in a log file, uploads the archive to an Amazon S3 bucket, and runs
unattended on a schedule through cron.

Script: [`backup-script.sh`](backup-script.sh)

---

## How it works

```
/root/bash                      source directory
      │
      │  tar -czvf
      ▼
/backup/file-backup-<timestamp>.tar.gz        local archive
      │
      │  aws s3 cp
      ▼
s3://s3-new-bash-course/                      off-server copy

every step also appended to /backup/logfile.log
```

| Stage | What the script does |
|---|---|
| Timestamp | Builds a unique filename from `date`, so no run overwrites another |
| Guard: CLI present | Exits with code 2 if the AWS CLI is not installed |
| Guard: archive exists | Exits with code 0 if an archive with this name is already there |
| Archive | `tar -czvf` into `/backup`, and checks the exit code before continuing |
| Upload | `aws s3 cp` to the bucket, and checks the exit code of that command |
| Log | Every outcome written to `/backup/logfile.log` through `tee -a` |

## Design points

Absolute paths throughout. cron does not run from the directory you expect,
so a relative source path fails silently when scheduled even though it works
when run by hand.

Each exit code checked on the line that follows its command. `$?` holds the
status of the *last* command only. Checking it after other commands have run
produces a script that reports success while nothing was uploaded.

`tee -a` instead of `>>`. The output appears on screen during a manual run
and is appended to the log for scheduled runs, from a single line.

Separate exit codes. `2` means the environment is wrong (no CLI), `1` means
the operation failed, `0` means the work was already done. A scheduler can then
distinguish the three.

## IAM

The instance carries an IAM role, so the script authenticates with temporary
credentials and no access keys are stored on disk. Access keys were also created
and tested with `aws configure` to compare both mechanisms, and
`aws sts get-caller-identity` confirmed which identity was in use.

For a lab the role used the managed `AmazonS3FullAccess` policy. In production
this should be a custom policy allowing only `s3:PutObject` on the single
destination bucket, following least privilege.

## Scheduling

Added to the root crontab so the backup runs daily at midnight:

```cron
0 0 * * * /root/backup-script.sh
```

Because `aws configure` was run as root, the credentials live in `/root/.aws/`.
A cron job owned by a different user would not find them, which is a common
cause of a backup that works by hand and fails on a schedule.

## Verification

| Check | Command | Result |
|---|---|---|
| Local archive created | `ls /backup` | Archive plus `logfile.log` present |
| Object reached S3 | `aws s3 ls s3://s3-new-bash-course` | Same filename and timestamp |
| Log recorded both stages | `cat /backup/logfile.log` | Backup message and upload message |
| Console agrees | S3 → General purpose buckets | Object listed with matching name and size |

## Setup

```bash
# 1. make it executable
chmod +x backup-script.sh

# 2. confirm the CLI is installed and authenticated
aws --version
aws sts get-caller-identity

# 3. run it once by hand
./backup-script.sh

# 4. schedule it
crontab -e
# add:  0 0 * * * /root/backup-script.sh
```

Adjust `Backup_file`, `Dest` and `S3_BUCKET` at the top of the script to match
your own paths and bucket. S3 bucket names are globally unique, so the bucket
name in this script will not be available to anyone else.
