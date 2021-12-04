ARG NGINX_VERSION=1.21.4
ARG ZT_VERSION=1.6.4

FROM nginx:${NGINX_VERSION}
LABEL maintainer="contact@jakoberpf.de"

RUN apt-get update && apt-get install -y jq curl npm && apt-get clean

RUN curl -o zerotier-install.sh https://raw.githubusercontent.com/jakoberpf/zerotier-scripts/main/zerotier-installer.sh && chmod +x zerotier-install.sh && /zerotier-install.sh

RUN npm i -g @laduke/zerotier-central-cli

RUN rc-update add iptables; \ 
    echo "tun" >> /etc/modules

COPY nginx.conf /etc/nginx/nginx.conf
COPY passthrough.conf /etc/nginx/passthrough.conf

ADD exec.sh /exec.sh

RUN chmod 755 /exec.sh

# CMD ["/exec.sh"]