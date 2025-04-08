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

DOMAINS_CONF="/config/domains.conf"
if [ ! -f "$DOMAINS_CONF" ]; then
    echo "File '$DOMAINS_CONF' does not exist"
    exit 1
fi

if [ -z $EMAIL ]; then
    echo "Missing ENV Parameter \$EMAIL"
    exit 1
fi

echo "Executing certificate creation.."
if [ $STAGING ]; then
    echo "STAGING MODE"
fi
if [ $DRY_RUN ]; then
    echo "DRY RUN"
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

echo "Finished certificate initiation"
