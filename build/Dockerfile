ARG CERTBOT_VERSION="v4.0.0"

FROM certbot/certbot:${CERTBOT_VERSION}
LABEL maintainer="mail@alexanderwolz.de"

ARG CERTBOT_VERSION

RUN apk add --no-cache bash docker-cli openssl \
    && addgroup -S -g 1000 letsencrypt \
    && adduser -S -u 1000 letsencrypt -G letsencrypt \
    && chown letsencrypt:letsencrypt /home/letsencrypt \
    && addgroup -S -g 998 docker \
    && adduser letsencrypt docker

WORKDIR /
COPY --chown=letsencrypt:letsencrypt config config
COPY --chown=letsencrypt:letsencrypt entrypoint.sh entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/letsencrypt
COPY --chown=letsencrypt:letsencrypt create.sh create.sh
COPY --chown=letsencrypt:letsencrypt init.sh init.sh
COPY --chown=letsencrypt:letsencrypt renew.sh renew.sh

ENV CERTBOT_VERSION=${CERTBOT_VERSION}
ENV CRON_PATTERN="0 3 * * *"
ENV WEBROOT="/var/www/certbot"
ENV STANDALONE=false
ENV DATA_VOLUME=""
ENV DATA_VOLUME_SUBFOLDER=""

CMD [ "/bin/bash" ]
ENTRYPOINT ["/entrypoint.sh"]
