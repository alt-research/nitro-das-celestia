FROM golang:1.22 AS builder

COPY . /src
WORKDIR /src

RUN cd cmd && go build -o celestia-server

FROM debian:stable-slim

WORKDIR /app

COPY --from=builder /src/cmd/celestia-server /app

CMD ["./celestia-server"]
