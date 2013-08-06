import os.path

RequestDir = os.environ['RequestDir']
DefaultBackupNode = os.environ['DefaultBackupNode']
Cmdir = os.environ['Cmdir']

Cmds = {
	'git'			:	os.path.join (Cmdir, 'backup_git "%s"'),
#	'mysqldb'		:	os.path.join (Cmdir, 'backup_mysqldb "%s"'),
	"postgresdb"		:	os.path.join (Cmdir, 'backup_postgresdb "%s"'),
	'trac'			:	os.path.join (Cmdir, 'backup_FS trac "%s"'),
	'app'			:	os.path.join (Cmdir, 'backup_FS app "%s"'),
	'drupal'		:	os.path.join (Cmdir, 'backup_FS drupal "%s"'),
	'dummy'			:	os.path.join (Cmdir, 'dummy "%s"'),
}

