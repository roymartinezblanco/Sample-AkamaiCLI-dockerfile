FROM alpine as base

FROM base as builder
ENV AKAMAI_CLI_HOME=/cli GOROOT=/usr/lib/go GOPATH=/go
RUN mkdir -p /cli/.akamai-cli
RUN apk add --no-cache bash python2 python2-dev py2-pip python3 python3-dev npm wget openssl openssl-dev curl nodejs build-base vim util-linux go dep go
RUN wget https://github.com/akamai/cli/releases/download/1.1.4/akamai-1.1.4-linuxamd64
RUN chmod +x akamai-1.1.4-linuxamd64 
RUN mv akamai-1.1.4-linuxamd64  /usr/local/bin/akamai
RUN pip install --upgrade pip && pip3 install --upgrade pip
RUN akamai install property
RUN akamai install property-manager

FROM base
USER root
RUN addgroup -S docker && adduser jenkins --disabled-password -S --uid 111 
ENV AKAMAI_CLI_HOME=/cli GOROOT=/usr/lib/go GOPATH=/go
RUN apk add --no-cache npm wget jq openssl openssh-client curl nodejs vim py2-pip python3 bash
RUN pip install --upgrade pip && \
    pip3 install --upgrade pip && \
    pip3 install netstorageapi && \
    rm -rf /root/.cache/pip/*
COPY --from=builder /cli /cli
COPY --from=builder /usr/local/bin/akamai /usr/local/bin/akamai
RUN mkdir /jenkins/
RUN echo 'eval "$(/usr/local/bin/akamai --bash)"' >> /jenkins/.bashrc 
RUN echo "[cli]" > /cli/.akamai-cli/config && \
    echo "cache-path            = /cli/.akamai-cli/cache" >> /cli/.akamai-cli/config && \
    echo "config-version        = 1.1" >> /cli/.akamai-cli/config && \
    echo "enable-cli-statistics = true" >> /cli/.akamai-cli/config && \
    echo "last-ping             = 2018-08-08T00:00:12Z" >> /cli/.akamai-cli/config && \
    echo "client-id             = devops-sandbox" >> /cli/.akamai-cli/config && \
    echo "install-in-path       =" >> /cli/.akamai-cli/config && \
    echo "last-upgrade-check    = ignore" >> /cli/.akamai-cli/config && \
    echo "stats-version         = 1.1" >> /cli/.akamai-cli/config
#ADD setup.py /jenkins
#RUN chmod +x /jenkins/setup.py 
RUN chown jenkins -R /jenkins/
RUN chown jenkins -R  /cli/
USER jenkins
VOLUME /jenkins
WORKDIR /jenkins
USER jenkins
CMD ["/bin/bash"]
