#!/bin/bash
#Build DB
#/d/projects/publicweb/publicweb-mysql-backup
IMAGENAME=publicweb-mysql
SQLSTORAGE=publicwebinfra_$IMAGENAME-storage
BACKUPSTORAGE=publicwebinfra_$IMAGENAME-backup
MYSQL_ROOT=devpass
GITURI="http://docker-ci:GEuQDKt3oTJsDVFu@git-azure.powerfarming.co.nz/gavin.jones/publicweb-mysql-backup.git"

docker stop $IMAGENAME
docker rm $IMAGENAME

docker volume rm $SQLSTORAGE
docker volume create --name $SQLSTORAGE

docker volume rm $BACKUPSTORAGE
docker volume create --name $BACKUPSTORAGE

#Importer
docker run --rm --name docker-toolbox \
    -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest sh -c "cd //mnt/backup && git clone $GITURI . "

#Check
#winpty docker run --rm -it --name docker-toolbox \
#    -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest bash

    #-v $IMAGENAME-backup:/docker-entrypoint-initdb.d \
    #-v //d/projects/publicweb/publicweb-mysql-backup:/docker-entrypoint-initdb.d \
echo Hit Ctrl+C once this is all set up
#echo Using BACKUP: $BACKUPVOL
docker run --rm --name $IMAGENAME  \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT \
    -e MYSQL_USER=$MYSQL_USER \
    -p "3306:3306" \
    -v $BACKUPVOL:/docker-entrypoint-initdb.d \
    -v $SQLSTORAGE:/var/lib/mysql \
    mysql:latest sh

sleep 60
docker stop $IMAGENAME
docker rm $IMAGENAME
#Wait for config to complete?

