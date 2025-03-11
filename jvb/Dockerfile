ARG JITSI_REPO=jitsi
ARG BASE_TAG=latest
FROM ${JITSI_REPO}/base-java:${BASE_TAG}

LABEL org.opencontainers.image.title="Jitsi Videobridge (jvb)"
LABEL org.opencontainers.image.description="WebRTC compatible server designed to route video streams amongst participants in a conference."
LABEL org.opencontainers.image.url="https://jitsi.org/jitsi-videobridge/"
LABEL org.opencontainers.image.source="https://github.com/jitsi/docker-jitsi-meet"
LABEL org.opencontainers.image.documentation="https://jitsi.github.io/handbook/"
# IF you need change the debian.sources
#RUN sed -i "s|http://deb.debian.org/|http://mirrors.tuna.tsinghua.edu.cn/|g" /etc/apt/sources.list.d/debian.sources
RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y jitsi-videobridge2 jitsi-autoscaler-sidecar jq curl iproute2 dnsutils libpcap0.8 && \
    apt-cleanup && \
    rm -rf /usr/share/jitsi-videobridge/lib

COPY rootfs/ /
COPY local_build/jitsi-videobridge.jar /usr/share/jitsi-videobridge
COPY local_build/lib /usr/share/jitsi-videobridge/lib
VOLUME /config
