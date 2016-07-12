#!/bin/bash
#Build DB
#/d/projects/publicweb/publicweb-mysql-backup
function abspath {
    if [[ -d "$1" ]]
    then
        pushd "$1" >/dev/null
        pwd
        popd >/dev/null
    elif [[ -e $1 ]]
    then
        pushd "$(dirname "$1")" >/dev/null
        echo "$(pwd)/$(basename "$1")"
        popd >/dev/null
    else
        echo "$1" does not exist! >&2
        return 127
    fi
}

IMAGENAME=publicweb-mysql
SQLSTORAGE=$IMAGENAME-storage
BACKUPSTORAGE=$IMAGENAME-backup
MYSQL_ROOT=devpass
GITURI="http://docker-ci:GEuQDKt3oTJsDVFu@git-azure.powerfarming.co.nz/gavin.jones/publicweb-mysql-backup.git"
LOCALBACKUP=$(abspath $(pwd)/../publicweb-mysql-backup)

docker stop $IMAGENAME
docker rm $IMAGENAME
docker stop $IMAGENAME-import
docker rm $IMAGENAME-import
docker rmi $IMAGENAME

docker volume rm $SQLSTORAGE
docker volume rm $BACKUPSTORAGE
docker volume create --name $SQLSTORAGE
docker volume create --name $BACKUPSTORAGE

#Importer
echo "Checking $LOCALBACKUP"
BACKUPFILES=$(ls -A $LOCALBACKUP)
if [ -z "$BACKUPFILES" ];
then
    echo $LOCALBACKUP was an empty folder, using GIT
    $LOCALBACKUP=""
fi

if [ -d "$LOCALBACKUP"  ] 
then
    #We have a local copy, use it
    echo "Using local backup from $LOCALBACKUP"
    LOCALBACKUP="/$LOCALBACKUP"
    docker run --rm --name docker-toolbox-mysql-import \
        -v $LOCALBACKUP://mnt/localbackup \
        -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest sh -c "cp -f /mnt/localbackup/* /mnt/backup"
else
    # Grab from git?
    echo "Grabbing from GIT at $GITURI"
    docker run --rm --name docker-toolbox-mysql-import \
        -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest sh -c "cd //mnt/backup && git clone $GITURI . "
fi

#Check
#winpty docker run --rm -it --name docker-toolbox \
#    -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest bash

    #-v $IMAGENAME-backup:/docker-entrypoint-initdb.d \
    #-v //d/projects/publicweb/publicweb-mysql-backup:/docker-entrypoint-initdb.d \
#echo Hit Ctrl+C once this is all set up
#echo Using BACKUP: $BACKUPVOL
#    -p "3306:3306" \

./build.sh 
docker run -d --name $IMAGENAME-import  \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT \
    -e MYSQL_USER=$MYSQL_USER \
    -v $BACKUPSTORAGE://docker-entrypoint-initdb.d \
    -v $SQLSTORAGE://var/lib/mysql \
    gavinjonespf/publicweb-mysql 

#Sleep and wait for exec?
for i in `seq 1 20`;
do
    echo Testing $i
    sleep 20
    TEST_DB=$(docker exec $IMAGENAME-import sh -c "mysql -p$MYSQL_ROOT -e 'show databases;' 2>&1")
    if [[ $TEST_DB == *"publicweb_aitchison_au"* ]]
    then
        echo "DB Restore started";
        #break;
    fi
    if [[ $TEST_DB == *"No such container"* ]]
    then
        echo "Something went horribly wrong - no such container";
        break;
    fi
    if [[ $TEST_DB == "Database information_schema mysql performance_schema" && $i -gt 5 ]]
    then
        echo "No data was restored - are you sure the git repo is set up correctly?";
        break;
    fi
#    if [[ $TEST_DB == *"publicweb_pfg"* ]]
#    then
#        echo "DB Restore started";
        #break;
#    fi
    if [[ $TEST_DB == *"publicweb_yanmar_stage"* ]]
    then
        echo "DB Restore likely complete";
        break;
    fi
done 

#Dead mans handle?
docker stop $IMAGENAME-import
docker rm $IMAGENAME-import
#Wait for config to complete?



