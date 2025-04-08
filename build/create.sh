#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>

while getopts d?s opt; do
    case $opt in
    d)
        DRY_RUN=1
        ;;
    s)
        STAGING=1
        ;;
    esac
done

shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

if [ -z $EMAIL ]; then
    echo "Missing ENV Parameter \$EMAIL"
    exit 1
fi

echo "executing pre script.."
source /config/pre.sh create

DOMAINS=$*

if [ "$STANDALONE" = true ] ; then
    COMMAND="certonly --authenticator standalone --non-interactive"
    if [ -z $DATA_VOLUME ]; then
        echo "Standalone Mode: Missing ENV Parameter \$DATA_VOLUME"
        exit 1
    fi
else
    COMMAND="certbot certonly --non-interactive --webroot -w $WEBROOT"
fi
#COMMAND+=" --rsa-key-size 4096" 
#COMMAND+=" --rsa-key-size 3072"
## read also https://stackoverflow.com/questions/589834/what-rsa-key-length-should-i-use-for-my-ssl-certificates
COMMAND+=" --rsa-key-size 2048"
COMMAND+=" --agree-tos --expand"
COMMAND+=" --email $EMAIL"

for DOMAIN in $DOMAINS; do
    COMMAND+=" -d $DOMAIN"
done

if [ $STAGING ]; then
    COMMAND+=" --staging"
fi

if [ $DRY_RUN ]; then
    COMMAND+=" --dry-run"
fi

if [ "$STANDALONE" = true ] ; then
    DOCKER_RUN="docker run --rm --name certbot-standalone -p 80:80"
    if [ ! -z "$DATA_VOLUME_SUBFOLDER" ]; then
        DOCKER_RUN+=" --mount source=\"$DATA_VOLUME\",target=/etc/letsencrypt,volume-subpath=$DATA_VOLUME_SUBFOLDER certbot/certbot:$CERTBOT_VERSION $COMMAND" 
    else
        DOCKER_RUN+=" -v \"$DATA_VOLUME:/etc/letsencrypt\" certbot/certbot:$CERTBOT_VERSION $COMMAND"
    fi
    eval $DOCKER_RUN || exit 1
else
    eval $COMMAND || exit 1
fi

if [ "$?" -ne 0 ]; then
    echo "Error while creating certificates for $DOMAINS"
    HAS_ERRORS=true
fi

echo "executing post script.."
source /config/post.sh create

if [ ! -z "$HAS_ERRORS" ]; then
    exit 1
fi