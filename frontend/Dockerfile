FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
ARG API_BASE_URL=https://api-dinamikutb.iscoutb.dev
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY --from=builder /src/build/web /usr/share/nginx/html

RUN printf '%s\n' \
  'server {' \
  '  listen 8080;' \
  '  server_name _;' \
  '  root /usr/share/nginx/html;' \
  '  index index.html;' \
  '  location / {' \
  '    try_files $uri $uri/ /index.html;' \
  '  }' \
  '  location = /health {' \
  '    access_log off;' \
  '    add_header Content-Type text/plain;' \
  '    return 200 "ok";' \
  '  }' \
  '}' > /etc/nginx/conf.d/default.conf

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget --spider --quiet http://127.0.0.1:8080/ || exit 1
