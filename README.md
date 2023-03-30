Docker Compose

You need to expose a config file directly into the container

```
version: '3'
services:
  caldera:
    privileged: true
    image: iotech17/caldera:latest
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
      - /path/to/file/conf.yml:/usr/src/app/conf/conf.yml:ro
      - app:/usr/src/app
    command: --fresh --log DEBUG --environment conf
    
    healthcheck:
      test: wget --no-check-certificate --spider -S http://localhost:8888 2>&1 > /dev/null | grep -q "200 OK$"
      interval: 60s
      retries: 5
      start_period: 20s
      timeout: 10s
volumes:
  app:
