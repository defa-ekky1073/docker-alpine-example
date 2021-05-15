#!/bin/bash

# check for mysql socket file dir
if [ -d "/run/mysqld" ]; then
	# claim the directory if exist
	chown -R mysql:mysql /run/mysqld
else 
	# create the directory and claim it if not exist
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

# check for data on mounted persistent volume
if [ -d /var/lib/mysql/mysql ]; then
	# claim the data if exist
	chown -R mysql:mysql /var/lib/mysql/mysql
else
	# initiate db if not exist
	chown -R mysql:mysql /var/lib/mysql
	mysql_install_db --user=mysql --ldata=/var/lib/mysql

	MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-""}
	MYSQL_DATABASE=${MYSQL_DATABASE:-""}
	MYSQL_USER=${MYSQL_USER:-""}
	MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

	cat << EOF > init.sql
USE mysql;
FLUSH PRIVILEGES ;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
EOF

	mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < init.sql
	rm -f init.sql
fi

exec mysqld --user=mysql --console --skip-name-resolve --skip-networking=0