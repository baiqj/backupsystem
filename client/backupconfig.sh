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

git_base="/path/to/git/repos"
postgres_db=""
trac="/path/to/trac"
wiki="/path/to/wiki"
wordpress="/path/to/wordpress"
dists_repos="/path/to/apt/repo1 /path/to/apt/repo2"

# Notification
Sendmail="/usr/bin/sendmail"
Administrators="a@example.com b@example.com"

export RequestDir
export Cmdir
export DefaultBackupNode
