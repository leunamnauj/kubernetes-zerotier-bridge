ARG ALPINE_VERSION=3.11
ARG CADDDY_VERSION=2.4.6

FROM caddy:${CADDDY_VERSION}-alpine as caddy

FROM alpine:${ALPINE_VERSION} as zerotier

ARG ZT_VERSION=1.6.4

RUN apk add --no-cache --update clang clang-dev alpine-sdk linux-headers \
  && git clone --depth 1 --branch ${ZT_VERSION} https://github.com/zerotier/ZeroTierOne.git /src \
  && cd /src \
  && make -f make-linux.mk zerotier-one

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="contact@jakoberpf.de"

RUN apk add --update --no-cache libc6-compat libstdc++ nss-tools jq curl

COPY --from=zerotier /src/zerotier-one /usr/sbin/

RUN mkdir -p /var/lib/zerotier-one \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli

# rc-update add iptables
# echo "tun" >> /etc/modules

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

RUN mkdir /etc/caddy/

ADD Caddyfile /etc/caddy/Caddyfile

ADD exec.sh /exec.sh

RUN chmod 755 /exec.sh

CMD ["/exec.sh"]