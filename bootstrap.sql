CREATE DATABASE metastore;
USE metastore;
SOURCE /usr/local/hive/scripts/metastore/upgrade/mysql/hive-schema-0.14.0.mysql.sql;
CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';
GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword';
flush privileges;
