Rationale
---------

A common pain point when using [MySQL](https://www.mysql.com/) [and](https://mariadb.org/) [friends](https://www.percona.com/software/mysql-database/percona-server) is managing backups. Generally the solutions on offer are focused on huge databases and are overly complex or time-consuming to setup. For small databases - like a database behind a content managed website - the overhead of setting up and maintaining MySQL backups can be disproportionate.

The other issue is that monolithic MySQL dumps tend to add up in size. The usual solution is to rotate out the backups and discard old ones based on what is ultimately an arbitrary schedule. When the backup you need is from eight days ago, you can be sure that you have only kept them for the last seven days. This problem can also be solved by implementing complex incremental backups or by shunting files off to cheaper storage like Amazon, but then every new step in the backup path is a new dependency or point of failure just waiting to ruin your day. Tools like [rdiff-backup](https://www.nongnu.org/rdiff-backup/) (sometimes via [Backupninja](https://0xacab.org/riseuplabs/backupninja)) are also used, but the stored diffs are hard to manually verify.

So the world needs a solution for MySQL which satisfies the 5 golden rules for simple and effective backup solutions, which I just made up (but sound pretty reasonable):

* Each backup run should finish quickly
* The backups should not require massive amounts of storage
* Backups should be verifiable as sane by a human with minimal effort
* Restoring backups from any point in time should be easy
* Backups should not be stored in proprietary data formats

A couple of years ago we created a tool which satisfies these requirements and is easy to understand, run, and modify for your own needs. Introducing MySQL SVN Backup. The name says it all really MySQL SVN Backup is a shell script that uses a combination of the “mysqldump” tool and the Subversion (or GIT) command-line client to backup MySQL databases to a Subversion (or GIT) repository.

The reasoning behind this approach is simple:

* Small databases don’t change very often, so we only need to backup the changes.
* MySQL databases can be dumped out to text format.
* Text files can be version controlled.
* Version control systems are common.
* Version control systems allow for easy verification of backup content.
* Version control systems allow for easy restoration of content at any point in time.

It can be configured to backup only specific databases and it can also exclude specific tables that aren’t suited to being backed up this way (or at all). By using Subversion (or GIT) we have access to dozens of tools for browsing backups online and restoring data. An unexpected advantage of this method has been the ease with which developers can grab a copy of production data for local development use. It’s just a matter of an SVN export (or GIT clone), which allows us to avoid giving developers access to production systems, or bugging our system administrators for database dumps. Another bonus is that we can account for schema changes over time. So we could potentially correlate and trace schema changes made by certain database migrations run by an application framework, as opposed to schema changes that have been made by a CMS plugin, or (god forbid) manually.

[< Back to project page](https://sambauers.github.io/mysql-svn-backup/)

[< Back to Github project](https://github.com/sambauers/mysql-svn-backup)
