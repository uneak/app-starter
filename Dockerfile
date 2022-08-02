#
# "caddy" stage
#
FROM caddy:${CADDY_VERSION}-builder-alpine AS caddy_builder_stage
# install Mercure and Vulcain modules
RUN xcaddy build \
    --with github.com/dunglas/mercure \
    --with github.com/dunglas/mercure/caddy \
    --with github.com/dunglas/vulcain \
    --with github.com/dunglas/vulcain/caddy


FROM caddy:${CADDY_VERSION} AS caddy_stage

WORKDIR /srv/api

COPY docker/caddy/Caddyfile /etc/caddy/Caddyfile