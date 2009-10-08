#!/bin/bash
set -u
sendmail="$(dirname $0)/sendmail.py"

gitbase="$1"
shift
receivers=$@


log="$(dirname $0)/logs/git-gc $(date "+%Y-%m-%d %H:%M:%S").log"

for repo in $gitbase/*.git
do
	if test -d "$repo"; then
		echo "git-dir=\"$repo\"" >> "$log"
			
		(	
			export GIT_DIR="$repo"
			git gc --aggressive
		) 1>>"$log" 2>&1
		
		echo "" >> "$log"
	fi
done

test -e "$log" && python "$sendmail" "git gc" "$log" "$receivers"

