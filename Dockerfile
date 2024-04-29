###########
# Builder
###########
FROM registry.access.redhat.com/ubi8/nodejs-18:1-102 as builder
WORKDIR /usr/src/app
USER root

# install node-gyp dependencies
RUN yum install -y python3 make gcc-c++

# install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy application dependency manifests to the container image.
COPY ./package.json ./package.json
COPY ./docker/nc-gui/ ./docker/nc-gui/
COPY ./docker/main.js ./docker/index.js
COPY ./docker/start-local.sh /usr/src/appEntry/start.sh
COPY src/public/ ./docker/public/

# for pnpm to generate a flat node_modules without symlinks
# so that modclean could work as expected
RUN echo "node-linker=hoisted" > .npmrc

# install production dependencies,
# reduce node_module size with modclean & removing sqlite deps,
# package built code into app.tar.gz & add execute permission to start.sh
RUN pnpm uninstall nocodb-sdk
RUN pnpm install --prod --shamefully-hoist --reporter=silent \
    && pnpm dlx modclean --patterns="default:*" --ignore="nc-lib-gui/**,dayjs/**,express-status-monitor/**,@azure/msal-node/dist/**" --run  \
    && rm -rf ./node_modules/sqlite3/deps \
    && tar -czf ../appEntry/app.tar.gz ./* \
    && chmod +x /usr/src/appEntry/start.sh

##########
# Runner
##########
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.9-1161
WORKDIR /usr/src/app

ENV NC_DOCKER 0.6
ENV NODE_ENV production
ENV PORT 8080
ENV NC_TOOL_DIR=/usr/app/data/

RUN apk --update --no-cache add \
    nodejs \
    tar \
    dumb-init \
    curl \
    jq

# Copy packaged production code & main entry file
COPY --from=builder /usr/src/appEntry/ /usr/src/appEntry/

EXPOSE 8080
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start Nocodb
CMD ["/usr/src/appEntry/start.sh"]
