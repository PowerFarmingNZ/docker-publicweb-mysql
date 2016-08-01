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
#Let's just use git for now
#LOCALBACKUP=$(abspath $(pwd)/../publicweb-mysql-backup)

docker stop $IMAGENAME
docker rm $IMAGENAME
docker stop $IMAGENAME-import
docker rm $IMAGENAME-import
docker rmi $IMAGENAME
docker stop docker-toolbox-mysql-backupbootstrap
docker rm docker-toolbox-mysql-backupbootstrap
docker stop docker-toolbox-mysql-import
docker rm docker-toolbox-mysql-import

docker volume rm $SQLSTORAGE
docker volume rm $BACKUPSTORAGE
docker volume create --name $SQLSTORAGE
docker volume create --name $BACKUPSTORAGE

#Importer
echo "Checking backup image"
BACKUPIMAGE=$(docker images | grep gavinjonespf/publicweb-mysql-backupbootstrap)
# docker run -it --name docker-toolbox-mysql-backupbootstrap -v publicweb-mysql-backupbootstrap://mnt/backup gavinjonespf/publicweb-mysql-backupbootstrap:latest sh

if [ ! -z "$BACKUPIMAGE"  ] 
then
    #We have a local copy, use it
    #TEST_DB
    #docker run -it --name docker-toolbox-mysql-backupbootstrap -v publicweb-mysql-backupbootstrap://mnt/backup gavinjonespf/publicweb-mysql-backupbootstrap:latest sh
    echo "Using local backup from $BACKUPIMAGE"
    #        -v $LOCALBACKUP://mnt/localbackup \
    docker run --rm --name docker-toolbox-mysql-import \
        -v $BACKUPSTORAGE://mnt/backup gavinjonespf/publicweb-mysql-backupbootstrap:latest sh -c "cp -f /mnt/localbackup/* /mnt/backup"
else
    # Grab from git?
    echo "Grabbing from GIT at $GITURI"
    docker run --rm --name docker-toolbox-mysql-import \
        -v $BACKUPSTORAGE://mnt/backup gavinjonespf/docker-toolbox:latest sh -c "cd //mnt/backup && git clone $GITURI . "
fi

#Check
#winpty docker run --rm -it --name docker-toolbox -v publicweb-mysql-backup://mnt/backup gavinjonespf/docker-toolbox:latest bash
#winpty docker logs -f publicweb-mysql-import

./build.sh 
#So this does the actual import from SQL scripts into the MySQL db...
docker run -d --name $IMAGENAME-import  \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT \
    -e MYSQL_USER=$MYSQL_USER \
    -v $BACKUPSTORAGE://docker-entrypoint-initdb.d \
    -v $SQLSTORAGE://var/lib/mysql \
    gavinjonespf/publicweb-mysql 

#Sleep and wait for exec?
#On local PC, restore process takes approx 30mins
for i in `seq 1 50`;
do
    echo Testing $i
    sleep 60
    TEST_DB=$(docker exec $IMAGENAME-import sh -c "mysql -p$MYSQL_ROOT -e 'show databases;'" 2>&1)
    if [[ $TEST_DB == *"publicweb_aitchison_au"* ]]
    then
        echo "DB Restore started";
        #break;
    fi
    if [[ $TEST_DB == *"No such container"* && $i -gt 2 ]]
    then
        echo "Something went horribly wrong - no such container";
        break;
    fi
    if [[ $TEST_DB == "Database information_schema mysql performance_schema" && $i -gt 5 ]]
    then
        echo "No data was restored - are you sure the git repo is set up correctly?";
        break;
    fi
    #Test logs instead
    TESTLOGS="$(docker logs $IMAGENAME-import 2>&1)"
    #echo $TESTLOGS
    if [[ $TEST_DB == *"mysqld: ready for connections"* ]]
    then
        echo "DB Restore is complete";
        break;
    fi

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



