FROM golang:1.12 AS backend-build

WORKDIR /go/src/app
COPY ./backend .

ENV GO111MODULE on
ENV GOPROXY https://goproxy.io

RUN go install -v ./...

FROM node:8.16.0-alpine AS frontend-build

ADD ./frontend /app
WORKDIR /app

# install frontend
RUN npm config set unsafe-perm true
RUN npm install -g yarn && yarn install

RUN npm run build:prod

# images
FROM ubuntu:latest

# set as non-interactive
ENV DEBIAN_FRONTEND noninteractive

# set CRAWLAB_IS_DOCKER
ENV CRAWLAB_IS_DOCKER Y

## RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-security main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-proposed main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list
## do update, upgrade (which may not be needed) & install:
RUN apt-get update -y && apt-get -y upgrade

# install packages
RUN apt-get install -y curl git net-tools iputils-ping ntp ntpdate python3 python3-pip nginx wget \
	&& ln -s /usr/bin/pip3 /usr/local/bin/pip \
	&& ln -s /usr/bin/python3 /usr/local/bin/python

# install dumb-init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/local/bin/dumb-init

# install backend
RUN pip install scrapy pymongo bs4 requests crawlab-sdk scrapy-splash

# add files
ADD . /app

# copy backend files
COPY --from=backend-build /go/bin/crawlab /usr/local/bin

# copy frontend files
COPY --from=frontend-build /app/dist /app/dist
COPY --from=frontend-build /app/conf/crawlab.conf /etc/nginx/conf.d

# working directory
WORKDIR /app/backend

# timezone environment
ENV TZ Asia/Shanghai

# frontend port
EXPOSE 8080

# backend port
EXPOSE 8000

# start backend
CMD ["/bin/bash", "/app/docker_init.sh"]
