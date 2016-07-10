FROM mysql:5.5
MAINTAINER Gavin Jones <gjones@powerfarming.co.nz>

ENV         DB_ENV_MYSQL_ROOT_PASSWORD ""
ENV         DB_ENV_MYSQL_USER ""
ENV         DB_ENV_MYSQL_PASSWORD ""

#Reference commit id
ARG COMMIT_ID
RUN         echo $COMMIT_ID >> commitid.txt
