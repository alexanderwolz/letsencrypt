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

if [ ! -f "$DOMAINS_CONF" ]; then
    echo "File '$DOMAINS_CONF' does not exist"
    exit 1
fi

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

echo "Executing certificate creation.."
if [ $STAGING ]; then
    echo "STAGING MODE"
fi
if [ $DRY_RUN ]; then
    echo "DRY RUN"
fi

#check if gateway is running
GATEWAY_NAME=$(docker ps --filter "publish=80" --format "{{.Names}}")
if [ ! -z "$GATEWAY_NAME" ]; then
    echo "stopping container $GATEWAY_NAME.."
    docker stop $GATEWAY_NAME >/dev/null
fi

#create certificates for (multi) domains
while IFS= read DOMAINS; do
    if [ ! -z "$DOMAINS" ] && [[ "$DOMAINS" != \#* ]]; then
        echo "Creating certificate for:"
        echo "- "$DOMAINS

        PARAMS=""
        if [ $DRY_RUN ]; then
            PARAMS+="d"
        fi
        if [ $STAGING ]; then
            PARAMS+="s"
        fi
        if [ $PARAMS ];then
            PARAMS="-"$PARAMS
        fi
        bash ./create.sh $PARAMS $DOMAINS
        if [ "$?" -ne 0 ]; then
            echo "Stopping here."
            break
        fi
    fi
done <$DOMAINS_CONF

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

echo "Finished certificate initiation"
