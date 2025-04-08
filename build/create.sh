#!/bin/bash

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

if [ -z "$DATA_VOLUME" ]; then
    echo "Missing ENV Parameter \$DATA_VOLUME"
    exit 1
fi

if [ -z $EMAIL ]; then
    echo "Missing ENV Parameter \$EMAIL"
    exit 1
fi

if [ -z $IMAGE ]; then
    echo "Missing ENV Parameter \$IMAGE"
    exit 1
fi

#check if gateway is running
GATEWAY_NAME=$(docker ps --filter "publish=80" --format "{{.Names}}")
if [ ! -z "$GATEWAY_NAME" ]; then
    echo "stopping container $GATEWAY_NAME.."
    docker stop $GATEWAY_NAME >/dev/null
fi

DOMAINS=$*
COMMAND="certonly --authenticator standalone --non-interactive"
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

if [ ! -z "$DATA_VOLUME_SUBFOLDER" ]; then
    docker run --rm --name certbot-standalone -p 80:80 --mount source="$DATA_VOLUME",target=/etc/letsencrypt,volume-subpath=$DATA_VOLUME_SUBFOLDER $IMAGE $COMMAND
else
    docker run --rm --name certbot-standalone -p 80:80 -v "$DATA_VOLUME:/etc/letsencrypt" $IMAGE $COMMAND
fi

if [ "$?" -ne 0 ]; then
    echo "Error while creating certificates for $DOMAINS"
    HAS_ERRORS=true
fi

#restart gateway again if it was running
if [ ! -z "$GATEWAY_NAME" ]; then
    echo "restarting container $GATEWAY_NAME.."
    docker start $GATEWAY_NAME >/dev/null
fi

if [ ! -z "$HAS_ERRORS" ]; then
    exit 1
fi