FROM frolvlad/alpine-glibc

RUN apk add --no-cache docker git bash curl

RUN curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose

RUN chmod +x /usr/bin/docker-compose

COPY run.sh /usr/bin/run.sh

RUN chmod +x /usr/bin/run.sh

ENTRYPOINT ["/usr/bin/run.sh"]
