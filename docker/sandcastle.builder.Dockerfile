FROM golang:1.18-alpine AS builder

RUN mkdir /app && mkdir /app/bin
RUN apk update && apk add make && apk add curl && apk add git && apk add protoc

ENV GOPATH=/go
ENV PROTOC=/usr/bin/protoc
