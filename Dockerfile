FROM alpine:latest
MAINTAINER Brad Bishop <bradleyb@fuzziesquirrel.com>

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --no-cache isync s6 vdirsyncer@testing

COPY s6 /etc/s6
COPY entrypoint.sh /

VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
