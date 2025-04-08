#!/bin/bash

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

#check if gateway is running
GATEWAY_NAME=$(docker ps --filter "publish=80" --format "{{.Names}}")
if [ ! -z "$GATEWAY_NAME" ]; then
    echo "stopping container $GATEWAY_NAME.."
    docker stop $GATEWAY_NAME >/dev/null
fi

COMMAND="renew --authenticator standalone"
if [ $DRY_RUN ]; then
    COMMAND+=" --dry-run"
fi

BEGIN=$(date -u +%s)

if [ ! -z "$DATA_VOLUME_SUBFOLDER" ]; then
    docker run --rm --name certbot-standalone -p 80:80 --mount source="$DATA_VOLUME",target=/etc/letsencrypt,volume-subpath=$DATA_VOLUME_SUBFOLDER $IMAGE $COMMAND
else
    docker run --rm --name certbot-standalone -p 80:80 -v "$DATA_VOLUME:/etc/letsencrypt" $IMAGE $COMMAND
fi
DURATION=$(($(date -u +%s)-$BEGIN))

#restart gateway again if it was running
if [ ! -z "$GATEWAY_NAME" ]; then
    echo "restarting container $GATEWAY_NAME.."
    docker start $GATEWAY_NAME >/dev/null
fi

#restart mailserver again if it was running
MAILSERVER_RUNNING=$(docker ps --filter "name=mailserver" -q)
if [ ! -z "$MAILSERVER_RUNNING" ]; then
    echo "restarting mailserver.."
    docker restart mailserver >/dev/null
fi

echo "Finished certificate renewal in $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds"
