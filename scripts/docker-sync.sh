#!/bin/bash

LINUX="linux/amd64"

if [ "$OS" == $LINUX ]; then
echo '
### GLOBALS ###
ARG GLIBC_RELEASE=2.34-r0

### GET ###
FROM alpine:latest as get

# prepare environment
WORKDIR /tmp

RUN apk --no-cache add unzip

# get bun
RUN wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip && \
    unzip bun-linux-x64.zip

# get glibc
ARG GLIBC_RELEASE
RUN wget https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_RELEASE}/glibc-${GLIBC_RELEASE}.apk


### IMAGE ###
FROM alpine:latest

# install bun
COPY --from=get /tmp/bun-linux-x64/bun /usr/local/bin

# prepare glibc
ARG GLIBC_RELEASE
COPY --from=get /tmp/sgerrand.rsa.pub /etc/apk/keys
COPY --from=get /tmp/glibc-${GLIBC_RELEASE}.apk /tmp

# install glibc
RUN apk --no-cache add /tmp/glibc-${GLIBC_RELEASE}.apk && \

# cleanup
    rm /etc/apk/keys/sgerrand.rsa.pub && \
    rm /tmp/glibc-${GLIBC_RELEASE}.apk && \

# smoke test
    bun --version

RUN mkdir /app

WORKDIR /app

RUN bun init

COPY . .

RUN apk --no-cache add nodejs npm

# RUN npm install -g npm@8.15.0

RUN bun install

EXPOSE 3000

CMD ["bun", "start"]

' > "Dockerfile"
else
echo '
FROM node:16.14

RUN mkdir /app

COPY package*.json /app

WORKDIR /app

RUN npm install -g npm@8.15.0

RUN yarn install

COPY . .

EXPOSE 3000

CMD ["yarn","start"]
' > "Dockerfile"
fi