# Download base image ubuntu
FROM ubuntu:24.04 LTS

# LABEL about the custom image
LABEL version="0.1"
LABEL maintainer="kiki_geraud@hotmail.fr"
LABEL description="This is custom Wireshark Docker Image using latest ubuntu/wireshark/xpra"

# skip interactive configuration dialogs
ENV DEBIAN_FRONTEND noninteractive

# add xpra repository and install Xpra and wireshark
RUN apt-get update && \
    apt install -y --no-install-recommends wget gnupg xvfb x11-xserver-utils python3-pip \
    && pip3 install pyinotify \
    && echo "deb [arch=amd64] https://xpra.org/ focal main" > /etc/apt/sources.list.d/xpra.list \
    && wget -q https://xpra.org/gpg.asc -O- | apt-key add - \
    && apt update \
    && apt install -y --no-install-recommends xpra-html5 \
    && apt-get remove -y --purge gnupg wget \
    && apt-get autoremove -y --purge
    && rm -rf /var/lib/apt/lists/*

# add xpra user
RUN useradd --create-home --shell /bin/bash xpra --gid xpra --uid 1000
WORKDIR /home/xpra

# create run directory for xpra socket and set correct permissions for xpra user
RUN mkdir -p /run/user/1000/xpra \
    && chown -R 1000 /run/user/1000

# allow users to read default certificate
RUN chmod 644 /etc/xpra/ssl-cert.pem

# expose xpra HTML5 client port
EXPOSE 14500

# install wireshark    
RUN apt-get update \
    && apt install -y --no-install-recommends binutils \
    && apt install -y --no-install-recommends wireshark \
    && apt-get remove -y --purge binutils \
    && apt-get autoremove -y --purge
    && rm -rf /var/lib/apt/lists/*

# allow non-root users to capture network traffic
RUN setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap

# set default password to access wireshark
ENV XPRA_PASSWORD wireshark

# xpra configuration when docker start
ENTRYPOINT ["xpra", "start", ":80", "--bind-tcp=0.0.0.0:14500", \
 "--mdns=no", "--webcam=no", "--no-daemon", "tcp-auth=env", "html=on",\
 "ssl-client-verify-mode=none", "socket-dirs=/run/user/1000/xpra", \
 "systemd-run=no", "ssl-cert=/etc/xpra/ssl-cert.pem"]
 
# start wireshark by default
CMD ["wireshark --fullscreen"]
