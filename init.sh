#Build DB
#/d/projects/publicweb/publicweb-mysql-backup
IMAGENAME=publicweb-mysql
SQLSTORAGE=$IMAGENAME-storage
MYSQL_ROOT=devpass
BACKUPVOL=//d/projects/publicweb/publicweb-mysql-backup

docker volume rm $SQLSTORAGE
docker volume create --name $SQLSTORAGE

    #-v $IMAGENAME-backup:/docker-entrypoint-initdb.d \
    #-v //d/projects/publicweb/publicweb-mysql-backup:/docker-entrypoint-initdb.d \
docker run --rm --name $IMAGENAME -P \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT \
    -e MYSQL_USER=$MYSQL_USER \
    -v $BACKUPVOL:/docker-entrypoint-initdb.d \
    -v $SQLSTORAGE:/var/lib/mysql \
    mysql:latest

