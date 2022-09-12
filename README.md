# caldera-docker

Dockerized version of Mitre Caldera Server

docker compose

```version: '3'
version: '3'
services:
  caldera:
    privileged: true
    image: iotech17caldera:latest
    ports:
      - "8888:8888"
      - "8443:8443"
      - "7010:7010"
      - "7011:7011/udp"
      - "7012:7012"
      - "8853:8853"
      - "8022:8022"
      - "2222:2222"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/acwg/Downloads/mwb.yml:/usr/src/app/conf/mwb.yml:ro
      - app:/usr/src/app
    command: --fresh --log DEBUG --environment mwb
volumes:
  app:
  ```

Simply pass the conf file directly into the container
