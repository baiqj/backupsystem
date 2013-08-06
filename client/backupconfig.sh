#!/bin/bash

Host="my_URL"
DefaultBackupNode="ssh://backupsrv@backup_server_URL/${Host}.git"

# Base layout
UtilsDir="/var/backup/scripts/utils"
Cmdir="/var/backup/scripts/cmds"
RequestDir="/var/backup/requests"
LogfileDir="/var/backup/log"
SendQueue="/var/backup/log/queues"
tmpDir="/var/backup/tmp"

# Backup sub-module related
Export_ssh="backupclient@$Host"

git_base="/var/www/code/git"
postgres_db=""
trac="/var/www/code"
app="/var/www/app"
drupal="/var/www/drupal"

# Notification
Sendmail="/usr/bin/sendmail"
Administrators="a@example.com b@example.com"

export RequestDir
export Cmdir
export DefaultBackupNode
