FROM alpine
MAINTAINER malvinas2@gmx.de

RUN apk --no-cache --no-progress upgrade && \ 
    apk --no-cache --no-progress add bash curl openvpn util-linux \
                 shadow tini tzdata coreutils procps nano openresolv privoxy

ENV PROVIDER=proton \
    PROTOCOL=udp \
    SERVER= \
    USERNAME= \
    PASSWORD= \
    HOST_NETWORK= \
    DNS_SERVERS_OVERRIDE=

COPY services /etc/openvpn
COPY update-resolv-conf_proton /etc/openvpn/
COPY config /etc/privoxy/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +r /etc/privoxy/config
RUN chmod +x /entrypoint.sh
RUN chmod +rwx /etc/openvpn/update-resolv-conf_proton

ENTRYPOINT [ "/sbin/tini", "--", "/entrypoint.sh" ]

EXPOSE 8118

