![MySQL SVN Backup logo](http://red-ant.github.com/mysql-svn-backup/images/mysql-svn-backup.png)

MySQL SVN Backup
================

MySQL SVN Backup provides an easy way to backup your MySQL database to an SVN repository.

This project is maintained by [Red Ant](http://redant.com.au/ "Visit Red Ant's website").

The pretty version of this information is [over here](http://red-ant.github.com/mysql-svn-backup/ "MySQL SVN Backup on GitHub Pages").

About MySQL SVN Backup
----------------------

When run locally on a MySQL platform it makes local dumps of databases table-by-table to files. These files are then automatically checked into a preconfigured Subversion repository.

The primary advantage is in having complete incremental historical snapshots of your database(s) available for potentially a longer time than standard monolithic database dumps.

If you find you need to transpose databases to other locations a lot, then storing your backups in Subversion can help to speed things up. Instead of waiting for an entire dump to be transferred, you can just keep a local working copy of the backup and update the incremental changes using Subversion before importing the data into MySQL.

This method and tool is not recommended for huge databases (or at least it hasn't been tested). It is probably also not much good for databases that store a lot of frequently changing binary data.

You can automate the backup process by setting up a cron job on your server.

Dependencies
------------

* Bash Shell
* MySQL command line client and MySQLDump
* Subversion
* A remote Subversion repository

Configuration
-------------

Copy all the conf/*.conf.example files to conf/*.conf

You should end up with:

* conf/local.conf
* conf/databases.conf
* conf/skiptables.conf

Read the comments in all the config files for configuration hints. Check the output in the log file (mysql-svn.log) for details of fatal errors.

Restoring from your backups
---------------------------

To restore from the file-per-table files, you can do the following from the designated dump directory:

	$ mysql -u root -p -e "CREATE DATABASE \`my_database\`;"
	$ cat my_database/*.sql | mysql -u root -p my_database

This will create the database and then concatenate the sql files and pass them through the mysql client to be executed.

License
-------

MySQL SVN Backup is distributed under the MIT license.

Logo from icons by [Yusuke Kamiyamane](http://p.yusukekamiyamane.com/ "Visit Yusuke Kamiyamane's website").
