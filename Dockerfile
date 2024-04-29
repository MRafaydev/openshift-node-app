FROM registry.access.redhat.com/ubi8/ubi:8.9-1160
WORKDIR /usr/src/app

ENV NC_DOCKER 0.6
ENV NODE_ENV production
ENV PORT 8080
ENV NC_TOOL_DIR=/usr/app/data/

RUN yum --update --no-cache add \
    nodejs \
    tar \
    dumb-init \
    curl \
    jq

EXPOSE 8080
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start Nocodb
CMD ["/usr/src/appEntry/start.sh"]
