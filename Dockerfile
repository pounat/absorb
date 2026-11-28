FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION=3.44.0
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}" \
    PUB_CACHE=/tmp/pub-cache
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        python3 \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --silent --show-error \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        | tar --extract --xz --directory /opt \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --enable-web \
    && flutter precache --web
WORKDIR /src
# Keep API/docs-only changes from invalidating the expensive Flutter compiler.
COPY pubspec.yaml pubspec.lock l10n.yaml .metadata ./
COPY lib/ ./lib/
COPY packages/ ./packages/
COPY assets/ ./assets/
COPY web/ ./web/
COPY shaders/ ./shaders/
RUN flutter pub get \
    && flutter build web --release --base-href /absorb/ \
        --no-web-resources-cdn --no-wasm-dry-run
COPY tools/finalize_web_update.py ./tools/finalize_web_update.py
RUN python3 tools/finalize_web_update.py

FROM python:3.13-alpine AS source
WORKDIR /src
COPY . .
RUN python tools/build_source_archive.py --root /src --output /out/absorb-web-source.tar.gz

FROM node:22-alpine AS api
ARG SOURCE_COMMIT=development
LABEL org.opencontainers.image.title="Absorb Web API" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}"
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY --chown=node:node server/ ./server/
USER node
EXPOSE 3000
CMD ["node", "server/index.mjs"]

FROM nginx:1.28-alpine AS web
ARG SOURCE_COMMIT=development
LABEL org.opencontainers.image.title="Absorb Web" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/pounat/absorb"
COPY deploy/nginx/nginx.conf /etc/nginx/nginx.conf
COPY deploy/nginx/web.conf /etc/nginx/conf.d/default.conf
COPY --from=build --chown=101:101 /src/build/web /usr/share/nginx/html/absorb
COPY --from=source --chown=101:101 /out/absorb-web-source.tar.gz /usr/share/nginx/html/source/absorb-web-source.tar.gz
COPY --chown=101:101 LICENSE /usr/share/nginx/html/source/LICENSE
USER nginx
EXPOSE 8080
ENTRYPOINT ["nginx", "-g", "daemon off;"]
