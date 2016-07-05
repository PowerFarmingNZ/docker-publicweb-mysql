#!/bin/bash
COMMITID=$1
PUSHNAME=$2
PUSHEMAIL=$3
REF=$4

if [ -z "$COMMITID" ]
then
    COMMITID=`date +%Y-%m-%d-%H%M%S`
fi

docker build --build-arg COMMIT_ID=$COMMITID -t gavinjonespf/publicweb-mysql .
