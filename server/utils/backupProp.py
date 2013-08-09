#!/usr/bin/python
import logging
import os

from gitosis import util

class BackupProp(util.RepoProp):
	name = "backup"
	log = logging.getLogger('BackupProp')
	post_update = os.path.join(os.path.dirname(__file__), 'post-update.template')
	backup_cfg = os.path.join(os.path.dirname(os.path.dirname(__file__)),
				  'backupconfig.sh')

	def _get(self, config, reponame):
		return True

	def action(self, repobase, name, reponame, ignore):
		if name == 'gitosis-admin': # Skip gitosis-admin.git
			self.log.debug('Skip control repo: gitosis-admin.git')
			return

		hooks_dir = os.path.join(repobase, name + '.git', 'hooks')
		path = os.path.join(hooks_dir, "tmp.post-update")

		self.log.debug('Generating %s' % os.path.join(hooks_dir, "post-update"))
		open(path, 'w').write("""#!/bin/bash
. %s
N="$TODOdir/%s"
. %s
""" % (self.backup_cfg, name, self.post_update))

		os.chmod(path, 0744)
		os.rename(path, os.path.join(hooks_dir, "post-update"))

def get_props():
	return (BackupProp(),)

