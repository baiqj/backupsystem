#!/bin/bash
set -e
default="/data/backup"

help ()
{
	echo "You need install gitosis first"
	echo "setup.sh <host-id> [path]"
}

if test $# -lt 1 -o "$1" == "-h" -o "$1" == "--help"; then
	help
	exit 0
elif test $# -lt 2; then
	target="$default"
	id -u "adminbackup" 1>/dev/null 2>&1 && target=~adminbackup
	host_id="$1"
else
	target="$1"
	host_id="$2"
fi
# canonicalize -> absolute_path
target=$(readlink -m "$target")

logdir="${target}/log"
datadir="${target}/data"
TODOdir="${target}/TODO"
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
	
	pre_exists_u=("git")
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
		sudo -H -u adminbackup ssh-keygen -C "adminbackup@${host_id}" -N "" -f "${target}/.ssh/id_rsa"
		
		echo "Adding user \"adminbackup\" to group \"git\""
		adduser adminbackup git
	fi
	push_note "Don't forget to Copy server's public key(\"${target}/.ssh/id_rsa.pub\") to clients"
}

mklayout ()
{
	mkdir -p "$logdir" && chown adminbackup:adminbackup "$logdir"
	mkdir -p "$datadir" && chown adminbackup:adminbackup "$datadir"

	mkdir -p "$TODOdir" && chown git:git "$TODOdir"
	chmod g+rwx "$TODOdir"
}

install_scripts ()
{
	exec_sources=("do_backup")
	normal_sources=("backupconfig.sh" "cmds/git.sh" "cmds/sftp.sh" "utils/gitosis-admin.post-update" "utils/post-update.template" "utils/sendmail.py" "utils/utils.sh")
	
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
		"Host=\"$host_id\""
		"TODOdir=\"$TODOdir\""
		"Cmdir=\"$cmdir\""
		"UtilsDir=\"$utilsdir\""
		"LogfileDir=\"$logdir\""
	)
	echo "Input administrators' emails here, e.g 'hello@example.com' 'hello2@example.com' ..."
	read notifies
	
	settings[${#settings[@]}]="Administrator=($notifies)"
	for setting in "${settings[@]}"
	do
		key=$(echo "$setting" | cut -d "=" -f 1)
		setting=${setting//\//\\\/}
		sed -i "s/^[ \t]*${key}=.*/${setting}/g" "${scriptsdir}/backupconfig.sh"
	done
	push_note "You can configure the backup system through \"${scriptsdir}/backupconfig.sh\""
}

echo "Install backup server(${host_id}) to \"${target}\""
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
echo "After configured gitosis, do the following:"
echo -e "\techo -e \"\npython \\\"${scriptsdir}/utils/gitosis-admin.post-update\\\"\" >>~git/repositories/gitosis-admin.git/hooks/post-update"
echo "Don't forget to set cron, e.g. add the following line to /etc/crontab:"
echo -e "\t0-59/5 * * * * adminbackup ${scriptsdir}/do_backup"
echo "You can additionally set apache to export git, you need to add user \"www-data\" to group \"adminbackup\""

