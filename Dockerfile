FROM ubuntu:16.04

RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

#forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

#Caddy
RUN wget https://github.com/mholt/caddy/releases/download/v0.9.1/caddy_linux_amd64.tar.gz \
 && tar -C /usr/local/bin -xvzf caddy_linux_amd64.tar.gz \
 && rm /caddy_linux_amd64.tar.gz \
 && mv /usr/local/bin/caddy_linux_amd64 /usr/local/bin/caddy

RUN caddy -version
#docker-gen
ENV DOCKER_GEN_VERSION 0.7.3
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock
EXPOSE 443
EXPOSE 80

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
