FROM alpine:3.20.0
LABEL maintainer="mail@alexanderwolz.de"

RUN apk add --no-cache bash docker-cli openssl \
    && addgroup -S -g 1000 letsencrypt \
    && adduser -S -u 1000 letsencrypt -G letsencrypt \
    && chown letsencrypt:letsencrypt /home/letsencrypt \
    && addgroup -S -g 998 docker \
    && adduser letsencrypt docker \
    #run once per day at 02:10 - 10 2 * * *
    && echo "10 2 * * * bash /home/letsencrypt/renew.sh" > /home/letsencrypt/.cronjob \
    && chown letsencrypt:letsencrypt /home/letsencrypt/.cronjob \
    #we need to run as root because of the docker socket
    && crontab -u root /home/letsencrypt/.cronjob

WORKDIR /home/letsencrypt

COPY --chown=letsencrypt:letsencrypt create.sh create.sh
COPY --chown=letsencrypt:letsencrypt init.sh init.sh
COPY --chown=letsencrypt:letsencrypt renew.sh renew.sh

ENV DATA_VOLUME=volume
#ENV DATA_VOLUME_SUBFOLDER=subfolder
ENV DOMAINS_CONF=/config/domains.conf

#USER letsencrypt #TODO let this container run as non-root
CMD [ "crond", "-f", "-L", "/dev/stdout" ]

#INFO: we dont inherit from certbot here, because if the gateway is down, we cant retrieve acme tokens.
# If it then runs at standalone, it needs to bind on port 80, which will not work if gateway runs.
# so either gateway needs to be runnable at all times or we spawn certbot from this alpine (See renew.sh)

#FROM certbot/certbot:v2.10.0

##override certbot entrypoint
#ENTRYPOINT [ ]