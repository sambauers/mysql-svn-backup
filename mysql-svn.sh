#!/bin/bash

# MySQL SVN Backup
#
# Copyright (c) 2012 Red Ant
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Find the base directory (resolving symbolic links)
BASE=`readlink -f $0`;
BASE=$( dirname $BASE );

# Include externally set variables
if [ -f $BASE/conf/local.conf ];
then
	. $BASE/conf/local.conf
fi

# Check for existence of critical SVN variables
if [ -z $SVNUSER ];
then
	echo "!!! INITIALIZATION ERROR: Missing SVNUSER in variables.";
	exit 10;
fi
if [ -z $SVNPASS ];
then
	echo "!!! INITIALIZATION ERROR: Missing SVNPASS in variables.";
	exit 11;
fi
if [ -z $SVNURI ];
then
	echo "!!! INITIALIZATION ERROR: Missing SVNURI in variables.";
	exit 12;
fi

# Array of databases to backup
DATABASES=`cat $BASE/conf/databases.conf`;

# Array of tables to skip, leave blank to backup all
SKIPTABLES=`cat $BASE/conf/skiptables.conf`;

# Defaults - Storage
if [ -z $LOGFILE ]; then LOGFILE=$BASE'/mysql-svn.log'; fi
if [ -z $DUMPDIR ]; then DUMPDIR=$BASE'/dump/'; fi

# Defaults - MySQL Executables
if [ -z $MYSQL ]; then MYSQL='/usr/bin/mysql'; fi
if [ -z $MYSQLDUMP ]; then MYSQLDUMP='/usr/bin/mysqldump'; fi

# Defaults - SVN Executable
if [ -z $SVN ]; then SVN='/usr/bin/svn'; fi

# in_array() function
function in_array() {
	local x
	ENTRY=$1
	shift 1
	ARRAY=( "$@" )
	[ -z "${ARRAY}" ] && return 1
	[ -z "${ENTRY}" ] && return 1
	for x in ${ARRAY[@]}; do
		[ "${x}" == "${ENTRY}" ] && return 0
	done
	return 1
}

# Start output
DATESTART=`date`;
echo ">>> ===============================================" >>$LOGFILE 2>&1;
echo ">>> Commence Backup at $DATESTART" >>$LOGFILE 2>&1;
echo ">>> ===============================================" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 1. Normalise storage" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;

# Create storage directory
if [ ! -d $DUMPDIR ];
then
	echo "!!! WARNING: No storage directory found at $DUMPDIR." >>$LOGFILE 2>&1;
	echo "!!!          Attempting to create storage directory." >>$LOGFILE 2>&1;
	echo "!!!" >>$LOGFILE 2>&1;
	mkdir -p $DUMPDIR >>$LOGFILE 2>&1;
	chmod 777 $DUMPDIR >>$LOGFILE 2>&1;
	echo "!!!" >>$LOGFILE 2>&1;

	# Test that the directory creation worked
	if [ ! -d $DUMPDIR ];
	then
		echo "!!! FATAL ERROR: The storage directory could not be created." >>$LOGFILE 2>&1;
		echo "!!!              Run the following command to determine the error." >>$LOGFILE 2>&1;
		echo "!!!" >>$LOGFILE 2>&1;
		echo "!!!              mkdir -p $DUMPDIR" >>$LOGFILE 2>&1;
		echo "!!!" >>$LOGFILE 2>&1;
		exit 1;
	fi
fi

echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 2. Normalise working copy" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;

# Check that there is a working copy
$SVN info $DUMPDIR >>$LOGFILE 2>&1;
LASTRESULT=$?;
echo ">>>" >>$LOGFILE 2>&1;

# Initialise working copy if not present
if [[ $LASTRESULT != 0 ]];
then
	echo "!!! WARNING: No working copy found in $DUMPDIR." >>$LOGFILE 2>&1;
	echo "!!! WARNING: Attempting to initialise working copy." >>$LOGFILE 2>&1;
	echo "!!!" >>$LOGFILE 2>&1;
	$SVN checkout --username $SVNUSER --password $SVNPASS --no-auth-cache --non-interactive $SVNURI $DUMPDIR >>$LOGFILE 2>&1;
	LASTRESULT=$?;
	echo "!!!" >>$LOGFILE 2>&1;

	# Fatal error if can't initialise
	if [[ $LASTRESULT != 0 ]];
	then
		echo "!!! FATAL ERROR: The working copy could not be initialised." >>$LOGFILE 2>&1;
		echo "!!!              Run the following command to determine the error." >>$LOGFILE 2>&1;
		echo "!!!" >>$LOGFILE 2>&1;
		echo "!!!              $SVN checkout --username $SVNUSER --password ********** --no-auth-cache --non-interactive $SVNURI $DUMPDIR" >>$LOGFILE 2>&1;
		echo "!!!" >>$LOGFILE 2>&1;
		exit 2;
	fi
fi

# Add authorisation if present
if [[ "$MYSQLHOST" != "" ]]; then MYSQLHOST="-h $MYSQLHOST"; fi
if [[ "$MYSQLUSER" != "" ]]; then MYSQLUSER="-u $MYSQLUSER"; fi
if [[ "$MYSQLPASS" != "" ]]; then MYSQLPASS="--password=$MYSQLPASS"; fi

echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 3. Get valid databases" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;

# Get all databases
ALLDATABASES=`$MYSQL $MYSQLHOST $MYSQLUSER $MYSQLPASS -B -N -e "SHOW DATABASES;"`;
LASTRESULT=$?;

# Fatal error if can't connect
if [[ $LASTRESULT != 0 ]];
then
	echo "!!! FATAL ERROR: Could not collect all database names." >>$LOGFILE 2>&1;
	echo "!!!              Run the following command to determine the error." >>$LOGFILE 2>&1;
	echo "!!!" >>$LOGFILE 2>&1;
	echo "!!!              $MYSQL $MYSQLHOST $MYSQLUSER --password=********** -B -N -e \"SHOW DATABASES;\"" >>$LOGFILE 2>&1;
	echo "!!!" >>$LOGFILE 2>&1;
	exit 3;
fi

echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 4. Dump tables" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;

# Iterate over databases
for DATABASE in $ALLDATABASES;
do
	# Only backup requested databases
	in_array "$DATABASE" "${DATABASES[@]}"
	if [[ $? != 0 ]];
	then
		continue;
	fi

	echo ">>>    * Database: $DATABASE" >>$LOGFILE 2>&1;

	# Create
	if [ ! -d $DUMPDIR/$DATABASE ];
	then
		mkdir -p $DUMPDIR/$DATABASE >>$LOGFILE 2>&1;
		chmod 777 $DUMPDIR/$DATABASE >>$LOGFILE 2>&1;
	fi

	TABLES=`$MYSQL $MYSQLHOST $MYSQLUSER $MYSQLPASS -B -N -e "SHOW TABLES;" $DATABASE`;

	for TABLE in $TABLES;
	do
		# Skip certain tables
		in_array "$DATABASE/$TABLE" "${SKIPTABLES[@]}"
		if [[ $? = 0 ]];
		then
			echo "!!!      - $TABLE (skipped)" >>$LOGFILE 2>&1;
			continue;
		fi

		echo ">>>      - $TABLE" >>$LOGFILE 2>&1;
		$MYSQLDUMP $MYSQLHOST $MYSQLUSER $MYSQLPASS --skip-dump-date --skip-extended-insert --hex-blob --order-by-primary --quick --log-error=$DUMPDIR/$DATABASE/errors.log -r $DUMPDIR/$DATABASE/$TABLE.sql $DATABASE $TABLE >>$LOGFILE 2>&1;
	done
done

echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 5. Add new files to working copy" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;
$SVN add -q $DUMPDIR* >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;
echo ">>> 6. Commit files to working copy" >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;
DATEEND=`date`;
$SVN commit --username $SVNUSER --password $SVNPASS --no-auth-cache --non-interactive -m "MySQL-SVN Backup $DATEEND" $DUMPDIR >>$LOGFILE 2>&1;
echo ">>>" >>$LOGFILE 2>&1;

# End output
echo ">>> ===============================================" >>$LOGFILE 2>&1;
echo ">>> Backup Complete at $DATEEND" >>$LOGFILE 2>&1;
echo ">>> ===============================================" >>$LOGFILE 2>&1;
echo "" >>$LOGFILE 2>&1;
exit 0;
