# Copyright (c) 2021 Eduardo Ramos (https://github.com/testillano/h1mock)
ARG base_tag=latest
FROM alpine:${base_tag}
COPY src /app
COPY deps/starter.sh /var/starter.sh

MAINTAINER testillano

ARG APP_VERSION=v0.1.0
LABEL testillano.h1mock.description="Docker image for HTTP/1 Mock Server Based in Python Flask"

RUN apk update && apk add \
    inotify-tools \
    python3 \
    py3-pip \
    vim curl

RUN pip3 install -r /app/requirements.txt

WORKDIR /app

#ENV TZ=Europe/Madrid

ENTRYPOINT ["sh", "/var/starter.sh"]
CMD []
