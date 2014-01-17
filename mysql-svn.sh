#!/bin/bash

# MySQL SVN Backup
#
# Copyright (c) 2012-2013 Red Ant
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
BASE=$( pwd -P );

# Include externally set variables
if [ -f $BASE/conf/local.conf ];
then
	. $BASE/conf/local.conf
fi

# Output echo helper functions
function echo_i() {
	echo "!!! INITIALIZATION ERROR:" $1;
}
function echo_o() {
	echo ">>>" $1;
}
function echo_w() {
	echo "!!!" $1;
}
function echo_b() {
	echo_o "===============================================";
	echo_o $1;
	echo_o "===============================================";
}

# Check which version control system is being used

# Check for existence of critical variable
if [ -z $REPOTYPE ];
then
	echo_i "Missing REPOTYPE in variables.";
	exit 100;
fi

case $REPOTYPE in
	'SVN' )
		# Check for existence of critical SVN variables
		if [ -z $SVNUSER ];
		then
			echo_i "Missing SVNUSER in variables.";
			exit 110;
		fi
		if [ -z $SVNPASS ];
		then
			echo_i "Missing SVNPASS in variables.";
			exit 111;
		fi
		if [ -z $SVNURI ];
		then
			echo_i "Missing SVNURI in variables.";
			exit 112;
		fi
	;;
	'GIT' )
		# Check for existence of critical GIT variables
		if [ -z $GITURI ];
		then
			echo_i "Missing GITURI in variables.";
			exit 120;
		fi
		if [ -z $GITBRANCH ];
		then
			echo_i "Missing GITBRANCH in variables.";
			exit 121;
		fi
	;;
esac

# Array of databases to backup
DATABASES=`cat $BASE/conf/databases.conf`;

# Array of tables to skip, leave blank to backup all
SKIPTABLES=`cat $BASE/conf/skiptables.conf`;

# Defaults - Storage
if [ -z $LOGSTORE ];
then
	LOGSTORE='file';
else
	if [[ "$LOGSTORE" != "screen" ]];
	then
		LOGSTORE='file';
	fi
fi
if [ -z $LOGFILE ];   then LOGFILE=$BASE'/mysql-svn.log';  fi
if [ -z $DUMPDIR ];   then DUMPDIR=$BASE'/dump';           fi
if [ -z $DATATYPES ]; then DATATYPES='all';                fi

# Defaults - MySQL Executables
if [ -z $MYSQL ];     then MYSQL='/usr/bin/mysql';         fi
if [ -z $MYSQLDUMP ]; then MYSQLDUMP='/usr/bin/mysqldump'; fi

# Defaults - SVN Executable
if [ -z $SVN ];       then SVN='/usr/bin/svn';             fi

# Defaults - GIT Executable
if [ -z $GIT ];       then GIT='/usr/bin/git';             fi

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

# Store output to a file if required
if [[ "$LOGSTORE" == "file" ]];
then
	exec >> $LOGFILE 2>&1;
fi

# Start output
DATESTART=`date`;
echo_b "Commence Backup at $DATESTART";
echo_o;
echo_o "1. Normalise storage";
echo_o;

# Create storage directory
echo_o "- Check for a local dump directory";
if [ ! -d $DUMPDIR ];
then
	echo_w "WARNING: No storage directory found at $DUMPDIR.";
	echo_w "         Attempting to create storage directory.";
	echo_w;
	mkdir -p $DUMPDIR;
	chmod 777 $DUMPDIR;
	echo_w;

	# Test that the directory creation worked
	if [ ! -d $DUMPDIR ];
	then
		echo_w "FATAL ERROR: The storage directory could not be created.";
		echo_w "             Run the following command to determine the error.";
		echo_w;
		echo_w "             mkdir -p $DUMPDIR";
		echo_w;
		exit 500;
	fi
fi

echo_o;
echo_o "2. Normalise working copy";
echo_o;

# Check that there is a working copy
echo_o "- Check for a working copy on the local dump directory";
case $REPOTYPE in
	'SVN' )
		$SVN info $DUMPDIR;
		LASTRESULT=$?;
	;;
	'GIT' )
		$GIT status $DUMPDIR;
		LASTRESULT=$?;
	;;
esac
echo_o;

# Initialise working copy if not present
if [[ $LASTRESULT != 0 ]];
then
	echo_w "WARNING: No working copy found in $DUMPDIR.";
	echo_w "WARNING: Attempting to initialise working copy.";
	echo_w;
	case $REPOTYPE in
		'SVN' )
			$SVN checkout --username $SVNUSER --password $SVNPASS --no-auth-cache --non-interactive $SVNURI $DUMPDIR;
			LASTRESULT=$?;
		;;
		'GIT' )
			$GIT clone --branch $GITBRANCH $GITURI $DUMPDIR;
			LASTRESULT=$?;
		;;
	esac
	echo_w;

	# Fatal error if can't initialise
	if [[ $LASTRESULT != 0 ]];
	then
		echo_w "FATAL ERROR: The working copy could not be initialised.";
		echo_w "             Run the following command to determine the error.";
		echo_w;
		case $REPOTYPE in
			'SVN' )
				echo_w "             $SVN checkout --username $SVNUSER --password ********** --no-auth-cache --non-interactive $SVNURI $DUMPDIR";
				;;
			'GIT' )
				echo_w "             $GIT clone --branch $GITBRANCH $GITURI $DUMPDIR";
				;;
		esac
		echo_w;
		exit 501;
	fi
else
	echo_o "- Update local dump directory from remote Subversion repository";
	case $REPOTYPE in
		'SVN' )
			$SVN update --username $SVNUSER --password $SVNPASS --no-auth-cache --non-interactive --accept theirs-full $DUMPDIR;
			LASTRESULT=$?;
		;;
		'GIT' )
			$GIT pull $DUMPDIR;
			LASTRESULT=$?;
		;;
	esac
	echo_o;

	# Fatal error if can't update
	if [[ $LASTRESULT != 0 ]];
	then
		echo_w "FATAL ERROR: The working copy could not be updated.";
		echo_w "             Run the following command to determine the error.";
		echo_w;
		case $REPOTYPE in
			'SVN' )
				echo_w "             $SVN update --username $SVNUSER --password ********** --no-auth-cache --non-interactive --accept theirs-full $DUMPDIR";
			;;
			'GIT' )
				echo_w "             $GIT pull $DUMPDIR";
			;;
		esac
		echo_w;
		exit 502;
	fi
fi

# Add authorisation if present
if [[ "$MYSQLHOST" != "" ]]; then MYSQLHOST="--host=$MYSQLHOST"; fi
if [[ "$MYSQLUSER" != "" ]]; then MYSQLUSER="--user=$MYSQLUSER"; fi
if [[ "$MYSQLPASS" != "" ]]; then MYSQLPASS="--password=$MYSQLPASS"; fi

echo_o;
echo_o "3. Get valid databases";
echo_o;

# Get all databases
ALLDATABASES=`$MYSQL $MYSQLHOST $MYSQLUSER $MYSQLPASS --batch --skip-column-names --execute="SHOW DATABASES;"`;
LASTRESULT=$?;

# Fatal error if can't connect
if [[ $LASTRESULT != 0 ]];
then
	echo_w "FATAL ERROR: Could not collect all database names.";
	echo_w "             Run the following command to determine the error.";
	echo_w;
	echo_w "             $MYSQL $MYSQLHOST $MYSQLUSER --password=********** --batch --skip-column-names --execute=\"SHOW DATABASES;\"";
	echo_w;
	exit 503;
fi

echo_o;
echo_o "4. Dump tables";
echo_o;

# Iterate over databases
for DATABASE in $ALLDATABASES;
do
	# Only backup requested databases
	in_array "$DATABASE" "${DATABASES[@]}"
	if [[ $? != 0 ]];
	then
		continue;
	fi

	echo_o "   * Database: $DATABASE";

	# Create
	if [ ! -d $DUMPDIR/$DATABASE ];
	then
		mkdir --parents $DUMPDIR/$DATABASE;
		chmod 777 $DUMPDIR/$DATABASE;
	fi

	TABLES=`$MYSQL $MYSQLHOST $MYSQLUSER $MYSQLPASS --batch --skip-column-names --execute="SHOW TABLES;" $DATABASE`;

	for TABLE in $TABLES;
	do
		# Skip certain tables
		in_array "$DATABASE/$TABLE" "${SKIPTABLES[@]}"
		if [[ $? = 0 ]];
		then
			echo_w "     - $TABLE (skipped)";
			continue;
		fi

		echo_o "     - $TABLE";

		# Do a distinct dump for each data type (usually it will just be "all")
		for DATATYPE in $DATATYPES;
		do
			case $DATATYPE in
				'all')
					# Don't skip anything
					OPTS='';
					SUFFIX='';
					;;

				'schema')
					# Skip table content output
					OPTS='--no-data';
					SUFFIX='-schema';
					;;
				'data')
					# Skip table creation output
					OPTS='--no-create-info';
					SUFFIX='-data';
					;;
				*)
					# Skip dump for unknown types
					echo_w "        DATATYPE: $DATATYPE (skipped unknown)";
					continue;
					;;
			esac

			echo_o "        DATATYPE: $DATATYPE";

			$MYSQLDUMP $MYSQLHOST $MYSQLUSER $MYSQLPASS $OPTS --skip-dump-date --skip-extended-insert --hex-blob --order-by-primary --quick --log-error=$DUMPDIR/$DATABASE/errors.log --result_file=$DUMPDIR/$DATABASE/$TABLE$SUFFIX.sql $DATABASE $TABLE;
		done
	done
done

echo_o;
echo_o "5. Add new files to working copy";
echo_o;
case $REPOTYPE in
	'SVN' )
		$SVN add --quiet --force $DUMPDIR/*;
		;;
	'GIT' )
		$GIT add $DUMPDIR;
		;;
esac
echo_o;
echo_o "6. Commit files to working copy";
echo_o;
DATEEND=`date`;
case $REPOTYPE in
	'SVN' )
		$SVN commit --username $SVNUSER --password $SVNPASS --no-auth-cache --non-interactive --message "MySQL-SVN Backup $DATEEND" $DUMPDIR;
		;;
	'GIT' )
		cd $DUMPDIR;
		$GIT commit -m "MySQL-SVN Backup $DATEEND";
		$GIT push $DUMPDIR;
		;;
esac
echo_o;

# End output
echo_b "Backup Complete at $DATEEND";
echo "";
exit 0;
