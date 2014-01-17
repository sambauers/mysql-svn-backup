MySQL SVN Backup
================

MySQL SVN Backup provides an easy way to backup your MySQL databases to an SVN or GIT repository.

This project is maintained by [Red Ant](http://redant.com.au/ "Visit Red Ant's website").

The pretty version of this information is [over here](http://mysql-svn-backup.redant.com.au/ "MySQL SVN Backup on GitHub Pages").

About MySQL SVN Backup
----------------------

When run locally on a MySQL platform it makes local dumps of databases table-by-table to files. These files are then automatically checked into a preconfigured Subversion or GIT repository.

The primary advantage is in having complete incremental historical snapshots of your database(s) available for potentially a longer time than standard monolithic database dumps.

If you find you need to transpose databases to other locations a lot, then storing your backups in a remote version control repository can help to speed things up. Instead of waiting for an entire dump to be transferred, you can just keep a local working copy of the backup and update the incremental changes using Subversion or GIT before importing the data into MySQL.

Some further rationale for it's existence is on [this blog post](http://redant.com.au/how-we-do/backing-up-mysql-into-subversion-using-mysql-svn-backup/ "Dolphins with lasers like to back up their databases to Subversion, how about you?").

This method and tool is not recommended for huge databases (or at least it hasn't been tested). It is probably also not much good for databases that store a lot of frequently changing binary data.

You can automate the backup process by setting up a cron job on your server.

Dependencies
------------

* Bash Shell
* MySQL command line client and MySQLDump
* Subversion or GIT command line tools
* A remote Subversion or GIT repository

Configuration
-------------

Move all the `conf/*.conf.example` files to `conf/*.conf`, here's a one-liner for that:

	$ for FILE in conf/*.example; do mv $FILE ${FILE%.example}; done

You should end up with:

* `conf/local.conf`
* `conf/databases.conf`
* `conf/skiptables.conf`

Read the comments in all the config files for configuration hints.

Usage
-----

Once configured you can run `mysql-svn.sh`

You will probably need to make the script executable:

	$ chmod 755 mysql-svn.sh

Then run the script without any options like this:

	$ ./mysql-svn.sh

The script does not report any status to the command line by default. This is because it is primarily designed to be invoked by a scheduler like *cron*. Check the output in the log file at `mysql-svn.log` for details of fatal errors, warnings and generally what happened during the backup run. If you really want the script to log output to the screen then you can adjust the LOGSTORE variable in `conf/local.conf`.

Restoring from your backups
---------------------------

To restore from the file-per-table files, you can do the following from the designated dump directory:

	$ mysql -u root -p -e "CREATE DATABASE \`my_database\`;"
	$ cat my_database/*.sql | mysql -u root -p my_database

This will create the database and then concatenate the sql files and pass them through the mysql client to be executed.

License
-------

MySQL SVN Backup is distributed under the MIT license. Go nuts.

Logo from icons by [Yusuke Kamiyamane](http://p.yusukekamiyamane.com/ "Visit Yusuke Kamiyamane's website").
