#!/bin/bash
set -e
default="/var/backup"
backup_user="backupclient"
backup_user_remote="backupsrv"

help ()
{
	echo "setup.sh <host-ip> [path]"
}

if test $# -lt 1 -o "$1" == "-h" -o "$1" == "--help"; then
	help
	exit 0
elif test $# -lt 2; then
	target=
	host_ip="$1"
else
	host_ip="$1"
	target="$2"
fi

notes=()
push_note ()
{
	note="$1"
	
	local len=${#notes[@]}
	notes[len]="$note"
}

create_backup_user()
{
	echo "Creating user '$backup_user' with HOME='$target'"
	test -d $(dirname "$target") || mkdir -p $(dirname "$target")
	useradd --system --shell /bin/bash --comment "$backup_user" --user-group --create-home \
	  --home-dir "$target" "$backup_user"
	sudo -H -u "$backup_user" ssh-keygen -C "$backup_user@$host_ip" -N "" -f "$target/.ssh/id_rsa"
	
	push_note "Don't forget to import client's public key('$target/.ssh/id_rsa.pub') to \
backup server's gitosis-admin.git"

	push_note "Adding user '$backup_user' to related group to grant access perms, e.g."
	push_note "	usermod -a $backup_user -G git; usermod -a $backup_user -G www-data"

	push_note "You need do visudo settings, add the following lines:"
	push_note "	$backup_user ALL = (root) NOPASSWD: /bin/chown, /bin/tar"
	push_note "	$backup_user ALL = (postgres) NOPASSWD: /usr/bin/pg_dump, /usr/bin/pg_dumpall"
}

check_prereq()
{
	local backup_user_exists=1

	if test "$(id -u $(whoami))" -ne 0; then
		echo "please run this script as root" >&2
		exit 2
	fi

	if id -u "$backup_user" &> /dev/null; then
		backup_user_exists=1
		target="$(eval echo ~$backup_user)"
	else
		backup_user_exists=0
		test -n "$target" || target="$default"
	fi

	read -p "Please specify /path/to/send_mail:" send_mail
	read -p "Please specify notification email(a@e.com b@e.com...):" notification_emails
	read -p "Please specify default backup server' URL:" default_backup_server

	# canonicalize -> absolute_path
	target=$(readlink -m "$target")

	logdir="${target}/log"
	sendrqdir="${logdir}/queues"
	tmpdir="${target}/tmp"
	rqdir="${target}/requests"

	scriptsdir="${target}/scripts"
	cmdir="${scriptsdir}/cmds"
	utilsdir="${scriptsdir}/utils"

	echo "Backup WorkingDir set to '$target'"
	test $backup_user_exists -eq 1 || echo "Will create dedicated user $backup_user"
	echo "send_mail: '$send_mail'"
	echo "Notification emails: $notification_emails"
	echo "Default backup server: $default_backup_server"
	read -p "Is above OK?(y/N)" answer

	if test "$answer" != "y"; then
		echo "Bye"
		exit 1
	fi

	if test $backup_user_exists -eq 0; then
		create_backup_user
	fi
}

mklayout ()
{
	for dir in "$logdir" "$tmpdir" "$rqdir" "$sendrqdir"
	do
                mkdir -p "$dir"
                chown "$backup_user:$backup_user" "$dir"
        done
}

install_scripts ()
{
	local cwd=$(pwd)

	exec_sources=("backup_all" "send_request" "backup_it")
	normal_sources=("backupconfig.sh" "backupconfig.py" "commitBackupRequest" "cmds/backup_FS" "cmds/backup_git" "cmds/backup_postgresdb" "cmds/dummy" "utils/utils.sh")
	
	for item in "${exec_sources[@]}"
	do
		echo "install \"${item}\"-> \"${scriptsdir}/${item}\" [mode 755]"
		install -p -D -m 755 -T "$item" "${scriptsdir}/${item}"
	done
	
	for item in "${normal_sources[@]}"
	do
		echo "install \"${item}\"-> \"${scriptsdir}/${item}\" [mode 744]"
		install -p -D -m 644 -T "$item" "${scriptsdir}/${item}"
	done
	
	echo "Setting scripts execution environment"
	settings=(
		"Host=\"${host_ip}\""
		"RequestDir=\"${rqdir}\""
		"SendQueue=\"${sendrqdir}\""
		"tmpDir=\"${tmpdir}\""
		"UtilsDir=\"$utilsdir\""
		"Cmdir=\"$cmdir\""
		"LogfileDir=\"$logdir\""
		"Sendmail=\"$send_mail\""
		"Administrators=\"$notification_emails\""
		"DefaultBackupNode=\"ssh://$backup_user_remote@$default_backup_server/$host_ip.git\""
	)

	for setting in "${settings[@]}"
	do
		key=$(echo "$setting" | cut -d "=" -f 1)
		sed -i "s|^[ \t]*${key}=.*|${setting}|g" "${scriptsdir}/backupconfig.sh"
	done
	
	push_note "You may need to configure the backup system through '$scriptsdir/backupconfig.sh'"
	
	echo "Inititalize queue for default backup server: $sendrqdir/$default_backup_server.git"
	cd /
	rm -rf "$sendrqdir/$default_backup_server.git"
	sudo -u "$backup_user" git --git-dir="$sendrqdir/$default_backup_server.git" init
	sudo -u "$backup_user" git --git-dir="$sendrqdir/$default_backup_server.git" config core.bare false
	sudo -u "$backup_user" git --git-dir="$sendrqdir/$default_backup_server.git" \
	  remote add origin "ssh://$backup_user_remote@$default_backup_server/$host_ip.git"
	cd "$cwd"

	push_note "To add more backup server, add *git control repo* in '$sendrqdir', \
set permissions through global gitosis"
	push_note "Also, import servers' public key to $backup_user/.ssh/authorized_keys, and"
	push_note "Modify $backup_user/.ssh/config like this:"
	push_note "Host $default_backup_server"
	push_note "  StrictHostKeyChecking no"
	push_note "  UserKnownHostsFile=/dev/null"

	echo "Installing '/etc/cron.d/backupclient' ..."
	cat > /etc/cron.d/backupclient <<EOF
0-59/5 * * * * $backup_user '$scriptsdir/send_request'

# Users of Arch Linux use the following line:
#0-59/5 * * * * su -c "'$scriptsdir/send_request'" $backup_user
EOF
	push_note "Note: for periodic backup, add entries to crontab, e.g."
	push_note "0 23 11 * * $backup_user '$scriptsdir/backup_all' &>/dev/null"
	push_node "Arch users also need to modify /etc/cron.d/backupclient"

	push_note "To enable git *realtime* backup, \
add the following line to .git/hooks/post-update:"
	push_note "  sudo -u $backup_user python '$scriptsdir/commitBackupRequest' \
git \"\$GIT_DIR\" &>/dev/null"
	push_note " and, visudo: 'git ALL = ($backup_user) NOPASSWD: /usr/bin/python'"
}

check_prereq
mklayout
install_scripts

echo
echo "***Note***"
for note in "${notes[@]}"
do
	echo "$note"
done

