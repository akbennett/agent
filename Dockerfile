FROM linarotechnologies/alpine:edge

RUN apk add --no-cache py-pip docker git bash curl

RUN pip install docker-compose

COPY run.sh /usr/bin/run.sh

RUN chmod +x /usr/bin/run.sh

ENTRYPOINT ["/usr/bin/run.sh"]
