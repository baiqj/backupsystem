import os.path

RequestDir = os.environ['RequestDir']
DefaultBackupNode = os.environ['DefaultBackupNode']
Cmdir = os.environ['Cmdir']

Cmds = {
	'git'			:	os.path.join (Cmdir, 'backup_git "%s"'),
	'rsync'			:	os.path.join (Cmdir, 'backup_dir "%s"'),
	'trac'			:	os.path.join (Cmdir, 'backup_FS trac "%s"'),
	'wiki'			:	os.path.join (Cmdir, 'backup_FS wiki "%s"'),
	'wordpress'		:	os.path.join (Cmdir, 'backup_FS wordpress "%s"'),
	"postgresdb"		:	os.path.join (Cmdir, 'backup_postgresdb "%s"'),
	'dummy'			:	os.path.join (Cmdir, 'dummy "%s"'),
}

