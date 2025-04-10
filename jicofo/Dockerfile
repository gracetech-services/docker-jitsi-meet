ARG JITSI_REPO=jitsi
ARG BASE_TAG=latest
FROM ${JITSI_REPO}/base-java:${BASE_TAG}

LABEL org.opencontainers.image.title="Jitsi Conference Focus (jicofo)"
LABEL org.opencontainers.image.description="Server-side focus component that manages media sessions and acts as load balancer."
LABEL org.opencontainers.image.url="https://github.com/jitsi/jicofo"
LABEL org.opencontainers.image.source="https://github.com/jitsi/docker-jitsi-meet"
LABEL org.opencontainers.image.documentation="https://jitsi.github.io/handbook/"
#IF you need change the debian.sources
#RUN sed -i "s|http://deb.debian.org/|http://mirrors.tuna.tsinghua.edu.cn/|g" /etc/apt/sources.list.d/debian.sources
RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y jicofo && \
    apt-cleanup && \
    rm -rf /usr/share/jicofo/lib
COPY rootfs/ /
COPY local_build/jicofo.jar /usr/share/jicofo
COPY local_build/lib /usr/share/jicofo/lib

VOLUME /config
