FROM alpine:latest

USER root

RUN apk update && apk add curl 

# Get kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

CMD exec /bin/bash -c "trap : TERM INT; sleep 3600 & wait"