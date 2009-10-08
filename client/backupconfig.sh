#!/bin/bash

Host="172.16.0.60"
Export_sftp="adminbackup@${Host}"
Export_git="git://${Host}"

DefaultBackupNode="ssh://git@172.16.2.57/${Host}.git"

UtilsDir="/var/backup/scripts/utils"
RequestDir="/var/backup/requests"
LogfileDir="/var/backup/log"
SendQueue="/var/backup/log/queues"
tmpDir="/var/backup/tmp"

git_base="/var/www/code/git"
postgres_db=""
trac="/var/www/code"
app="/var/www/app"
drupal="/var/www/drupal"

Administrator=("chenj@lemote.com")
#TODOdir=/path/to/TODO/dir
