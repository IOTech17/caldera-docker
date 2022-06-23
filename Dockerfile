FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get -y install python3 python3-pip git upx zlib1g curl

#WIN_BUILD is used to enable windows build in sandcat plugin
ARG WIN_BUILD=true
RUN if [ "$WIN_BUILD" = "true" ] ; then apt-get -y install mingw-w64; fi

RUN git clone --recursive https://github.com/mitre/caldera.git .

# Install pip requirements
#ADD requirements.txt .
RUN sed -i 's/pyminizip==0.2.4/pyminizip==0.2.6/g' requirements.txt

RUN pip3 install --no-cache-dir -r requirements.txt
RUN pip3 install markupsafe==2.0.1

# Install golang
RUN curl -L https://go.dev/dl/go1.17.6.linux-amd64.tar.gz -o go1.17.6.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz;
ENV PATH="${PATH}:/usr/local/go/bin"
RUN go version;

# Compile default sandcat agent binaries, which will download basic golang dependencies.
WORKDIR /usr/src/app/plugins/sandcat

ADD ./payloads/. /usr/src/app/plugins/emu/payloads/

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
RUN if [ ! -d "/usr/src/app/plugins/atomic/data/atomic-red-team" ]; then   \
    git clone --depth 1 https://github.com/redcanaryco/atomic-red-team.git \
        /usr/src/app/plugins/atomic/data/atomic-red-team;                  \
fi


#install builder plugin dependencies
WORKDIR /usr/src/app/plugins/builder

#RUN ./install.sh

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app/plugins/human

RUN pip3 install --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app

RUN apt-get remove --purge -y --allow-remove-essential apt wget curl && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN useradd -ms /bin/bash caldera

#RUN chown -R caldera:caldera /usr/src/app

#USER caldera

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
