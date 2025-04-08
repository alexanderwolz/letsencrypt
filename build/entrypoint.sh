#!/bin/bash
# Copyright (C) 2023 Alexander Wolz <mail@alexanderwolz.de>

if [ -z "$CRON_PATTERN" ]; then
    echo "Missing ENV Parameter \$CRON_PATTERN"
    exit 1
fi

echo "Starting letsencrypt renew with CRON pattern \"$CRON_PATTERN\""
if [ "$STANDALONE" = true ] ; then
    echo "  -> Using standalone authenticator"
    if [ -z $DATA_VOLUME ]; then
        echo "Missing ENV Parameter \$DATA_VOLUME (volume or local mount folder)"
        exit 1
    fi
else
    echo "  -> Using webroot, check if external webserver is running and serving \"$WEBROOT\""
fi

echo "$CRON_PATTERN bash /home/letsencrypt/renew.sh" > /home/letsencrypt/.cronjob
chown letsencrypt:letsencrypt /home/letsencrypt/.cronjob
crontab -u root /home/letsencrypt/.cronjob

crond -f -L /dev/stdout
