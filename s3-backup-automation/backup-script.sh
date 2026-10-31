#!/bin/bash
#
# Compresses a source directory into a timestamped tar.gz archive, logs every
# step, and replicates the archive to an Amazon S3 bucket. Designed to run
# unattended from cron, so all paths are absolute.

time=$(date +%m-%d-%y_%H_%M_%S)
Backup_file="/root/bash"
Dest="/backup"
filename="file-backup-$time.tar.gz"
LOG_FILE="/backup/logfile.log"
S3_BUCKET="s3-new-bash-course"
FILE_TO_UPLOAD="$Dest/$filename"

mkdir -p "$Dest"

# --- is the AWS CLI available? ---
if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install it first" | tee -a "$LOG_FILE"
        exit 2
fi

# --- does this archive already exist? ---
if [ -f "$FILE_TO_UPLOAD" ]; then
        echo "The file $filename already exists!" | tee -a "$LOG_FILE"
        exit 0
fi

# --- create the compressed archive ---
tar -czvf "$FILE_TO_UPLOAD" "$Backup_file"
if [ $? -ne 0 ]; then
        echo "Backup FAILED for $Backup_file" | tee -a "$LOG_FILE"
        exit 1
fi
echo "Backup completed successfully. Backup file: $FILE_TO_UPLOAD" | tee -a "$LOG_FILE"

# --- replicate to S3 ---
aws s3 cp "$FILE_TO_UPLOAD" "s3://$S3_BUCKET/"
if [ $? -eq 0 ]; then
        echo "File uploaded successfully to the S3 bucket: $S3_BUCKET" | tee -a "$LOG_FILE"
else
        echo "File upload to S3 failed" | tee -a "$LOG_FILE"
        exit 1
fi
