#FROM registry.access.redhat.com/ubi8/nodejs-20
FROM registry.access.redhat.com/ubi8/nodejs-18:1-102 as builder


USER 0
RUN fix-permissions ./
USER root

RUN yum install --disableplugin=subscription-manager python2  openssl-devel cyrus-sasl -y \
    && yum clean --disableplugin=subscription-manager packages \
    && ln -s /usr/bin/python2 /usr/bin/python \
    && useradd --uid 1000 --gid 0 --shell /bin/bash --create-home node


RUN mkdir ./app
WORKDIR $HOME/app
COPY package.json .
RUN npm install --omit=dev
COPY server ./server
COPY public ./public

ENV NODE_ENV production
ENV PORT 3000

EXPOSE 3000

CMD ["node", "server/server.js"]
