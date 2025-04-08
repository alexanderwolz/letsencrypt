#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>

NOW=$(date +"%Y%m%d_T%H%M%S")
echo "---------------------------------------------------------------"
echo "Executing renew script at $(date)"

while getopts d opt; do
    case $opt in
    d)
        DRY_RUN=1
        ;;
    esac
done

MSG="Starting certificate renewal as user $(whoami)"
if [ $DRY_RUN ]; then
    MSG+=" with DRY RUN!"
fi
echo $MSG

source /config/pre.sh renew

if [ "$STANDALONE" = true ] ; then
    COMMAND="renew --authenticator standalone"
    if [ -z $DATA_VOLUME ]; then
        echo "Standalone Mode: Missing ENV Parameter \$DATA_VOLUME"
        exit 1
    fi
else
    COMMAND="certbot renew --non-interactive --webroot -w $WEBROOT"
fi

if [ $DRY_RUN ]; then
    COMMAND+=" --dry-run"
fi

BEGIN=$(date -u +%s)

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


DURATION=$(($(date -u +%s)-$BEGIN))

source /config/post.sh renew

echo "Finished certificate renewal in $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
