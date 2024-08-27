FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install python3 python3-pip python3-venv git curl golang-go upx zlib1g wget unzip npm nodejs libxml2 libxslt1-dev
    
RUN git config --global http.postBuffer 1048576000

#WIN_BUILD is used to enable windows build in sandcat plugin
ARG WIN_BUILD=true
RUN if [ "$WIN_BUILD" = "true" ] ; then apt-get -y install mingw-w64; fi

RUN git clone --recursive https://github.com/mitre/caldera.git .

# Set up python virtualenv
ENV VIRTUAL_ENV=/opt/venv/caldera
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app/plugins/sandcat/gocat
RUN go mod tidy && go mod download

# Compile default sandcat agent binaries, which will download basic golang dependencies.
WORKDIR /usr/src/app/plugins/sandcat

RUN ./update-agents.sh

# Check if we can compile the sandcat extensions, which will download golang dependencies for agent extensions
RUN mkdir /tmp/gocatextensionstest
RUN cp -R ./gocat /tmp/gocatextensionstest/gocat
RUN cp -R ./gocat-extensions/* /tmp/gocatextensionstest/gocat/

RUN cp ./update-agents.sh /tmp/gocatextensionstest/update-agents.sh

WORKDIR /tmp/gocatextensionstest

RUN mkdir /tmp/gocatextensionstest/payloads

RUN ./update-agents.sh

# Clone atomic red team repo for the atomic plugin
RUN git clone --depth 1 https://github.com/redcanaryco/atomic-red-team.git \
        /usr/src/app/plugins/atomic/data/atomic-red-team;

WORKDIR /usr/src/app/plugins/emu

# If emu is enabled, complete necessary installation steps
RUN pip3 install -r requirements.txt && ./download_payloads.sh;

#install builder plugin dependencies
WORKDIR /usr/src/app/plugins/builder

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app/plugins/human

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app/plugins/stockpile

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app

RUN (cd plugins/magma && npm install) && \
    (cd plugins/magma && npm run build) && \
    pip3 install pyminizip setuptools && \
    apt-get remove --purge -y --allow-remove-essential apt &&\ 
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /usr/src/app

STOPSIGNAL SIGINT

# Default HTTP port for web interface and agent beacons over HTTP
EXPOSE 8888

# Default HTTPS port for web interface and agent beacons over HTTPS (requires SSL plugin to be enabled)
EXPOSE 8443

# TCP and UDP contact ports
EXPOSE 7010
EXPOSE 7011/udp

# Websocket contact port
EXPOSE 7012

# Default port to listen for DNS requests for DNS tunneling C2 channel
EXPOSE 8853

# Default port to listen for SSH tunneling requests
EXPOSE 8022

# Default FTP port for FTP C2 channel
EXPOSE 2222

ENTRYPOINT ["python3", "server.py"]
