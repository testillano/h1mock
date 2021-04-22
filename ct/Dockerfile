ARG base_tag=latest
FROM alpine:${base_tag}
MAINTAINER testillano

LABEL testillano.ct_h1mock.description="Docker image for h1mock component test"

RUN apk update && apk add \
    pytest \
    python3 \
    py3-pip \
    vim

COPY examples /pytest/resources
COPY ct/src /pytest
WORKDIR /pytest

RUN pip3 install -r requirements.txt

CMD [ "sleep", "infinity" ]
