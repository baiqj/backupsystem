#!/bin/bash
set -e
default="/var/backup"

help ()
{
	echo "setup.sh <host-ip> [path]"
}

if test $# -lt 1 -o "$1" == "-h" -o "$1" == "--help"; then
	help
	exit 0
elif test $# -lt 2; then
	target="$default"
	id -u "adminbackup" 1>/dev/null 2>&1 && target=~adminbackup
	host_ip="$1"
else
	target="$1"
	host_ip="$2"
fi
# canonicalize -> absolute_path
target=$(readlink -m "$target")

logdir="${target}/log"
sendrqdir="${logdir}/queues"
tmpdir="${target}/tmp"
rqdir="${target}/requests"

scriptsdir="${target}/scripts"
cmdir="${scriptsdir}/cmds"
utilsdir="${scriptsdir}/utils"

notes=()
push_note ()
{
	note="$1"
	
	local len=${#notes[@]}
	notes[len]="$note"
}


check_prereq ()
{
	if test "$(id -u $(whoami))" -ne 0; then
		echo "please run this script as root"
		exit -1
	fi
	
	pre_exists_u=("git" "www-data")
	for u in "${pre_exists_u[@]}"
	do
		id -u "$u" 1>/dev/null 2>&1 || (echo "user $u not exists, you need install & configure some software"; exit -1)
	done
}

mainuser_setting_up ()
{
	local mainuser_exists=1
	id -u "adminbackup" 1>/dev/null 2>&1 || mainuser_exists=0
	
	if test $mainuser_exists -eq 1; then
		test ~adminbackup = "$target" || (echo "install_path \"$target\" isn't HOME of existing user adminbackup"; exit -1)
	else
		echo "Add user \"adminbackup\" (HOME: ${target})"
		test -d $(dirname "$target") || mkdir -p $(dirname "$target")
		adduser --system --shell /bin/bash --gecos 'adminbackup' --group --disabled-password --home "$target" adminbackup
		chown adminbackup:adminbackup "$target"

		echo "Adding user \"adminbackup\" to group \"git\""
		adduser adminbackup git
		echo "Adding user \"adminbackup\" to group \"www-data\""
		adduser adminbackup www-data
	fi
	push_note "You need do visudo settings, add the following lines:"
	push_note "	adminbackup ALL = (root) NOPASSWD: /bin/chown, /bin/tar"
	push_note "	adminbackup ALL = (postgres) NOPASSWD: /usr/bin/pg_dump, /usr/bin/pg_dumpall"
}

mklayout ()
{
	mkdir -p "$logdir" && chown adminbackup:adminbackup "$logdir"
	mkdir -p "$tmpdir" && chown adminbackup:adminbackup "$tmpdir"
	mkdir -p "$rqdir" && chown adminbackup:adminbackup "$rqdir"
	mkdir -p "$sendrqdir" && chown adminbackup:adminbackup "$sendrqdir"
}

install_scripts ()
{
	exec_sources=("backup_all" "send_request")
	normal_sources=("backupconfig.sh" "backupconfig.py" "commitBackupRequest" "cmds/backup_FS" "cmds/backup_git" "cmds/backup_postgresdb" "cmds/dummy" "utils/sendmail.py" "utils/utils.sh")
	
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
		"LogfileDir=\"$logdir\""
	)
	pysettings=(
		"RequestDir=\"${rqdir}\""
	)
	echo "Input URL of default backup server:"
	read default_backup_node
	settings[${#settings[@]}]="DefaultBackupNode=\"ssh://git@${default_backup_node}/${host_ip}.git\""
	pysettings[${#pysettings[@]}]="DefaultBackupNode=\"${default_backup_node}\""
	
	echo "Input administrators' emails here, e.g 'hello@example.com' 'hello2@example.com' ..."
	read notifies
	settings[${#settings[@]}]="Administrator=(${notifies})"
	
	for setting in "${settings[@]}"
	do
		key=$(echo "$setting" | cut -d "=" -f 1)
		setting=${setting//\//\\\/}
		sed -i "s/^[ \t]*${key}=.*/${setting}/g" "${scriptsdir}/backupconfig.sh"
	done
	
	for pysetting in "${pysettings[@]}"
	do
		key=$(echo "$pysetting" | cut -d "=" -f 1)
		val=$(echo "$pysetting" | cut -d "=" -f 2-)
		val=${val//\//\\\/}
		sed -i "s/^[ \t]*${key}[ \t]*=.*/${key} = ${val}/g" "${scriptsdir}/backupconfig.py"
	done
	push_note "You may need to configure the backup system through \"${scriptsdir}/backupconfig.sh\" & \"${scriptsdir}/backupconfig.py\""
	
	echo "Inititalize queue for default backup server: ${sendrqdir}/${default_backup_node}.git"
	
	sudo -u adminbackup git --git-dir="${sendrqdir}/${default_backup_node}.git" init
	sudo -u adminbackup git --git-dir="${sendrqdir}/${default_backup_node}.git" config core.bare false
	sudo -u adminbackup git --git-dir="${sendrqdir}/${default_backup_node}.git" remote add origin "ssh://git@${default_backup_node}/${host_ip}.git"
	push_note "To add more backup server, add *git control repo* in ${sendrqdir}, set permissions through global gitosis"
	push_note "Also, import servers' public key to ~adminbackup/.ssh/authorized_keys, change ~adminbackup/.ssh/config like this:"
	push_note "		Host 172.16.2.57"
	push_note "		  StrictHostKeyChecking no"
	push_note "		  UserKnownHostsFile=/dev/null"
}

echo "Install backup client(${host_ip}) to \"${target}\""
check_prereq
mainuser_setting_up
mklayout
install_scripts

echo
echo "***Note***"
for note in "${notes[@]}"
do
	echo "$note"
done

echo "Don't forget to set cron, e.g. add the following lines to /etc/crontab:"
echo "	0-59/5 * * * * adminbackup /var/backup/scripts/send_request"
echo "	0    23 11 * * adminbackup /var/backup/scripts/backup_all 1>/dev/null
2>&1"

echo "To enable backup git repo in *realtime*, add the following line to .git/hooks/post-update:"
echo "	sudo -u adminbackup python \"${scriptsdir}/commitBackupRequest\" git
\"$PWD\" 1>/dev/null 2>&1"
echo "	to make the above work, visudo: git ALL = (adminbackup) NOPASSWD: /usr/bin/python"

