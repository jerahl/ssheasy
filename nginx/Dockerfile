FROM golang:1.23.3-alpine as builder

WORKDIR /go/src/web

COPY ./web .


RUN GOOS=js GOARCH=wasm go build -o main.wasm


FROM nginx:1.23.3
COPY --from=builder /usr/local/go/misc/wasm/wasm_exec.js /usr/share/nginx/html/
# Add the Nginx configuration file
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
# Render sheasy-config.js from $SSHEASY_DECRYPT_KEY on every container start
COPY ./nginx/docker-entrypoint.d/10-sheasy-config.sh /docker-entrypoint.d/10-sheasy-config.sh
RUN chmod +x /docker-entrypoint.d/10-sheasy-config.sh
# Copy over static assets from the client application
COPY ./web/html /usr/share/nginx/html
COPY --from=builder /go/src/web/main.wasm /usr/share/nginx/html/
# Fail loudly if the embed assets are missing (e.g. building from a stale
# checkout / wrong branch) instead of silently shipping a broken image.
RUN test -f /usr/share/nginx/html/terminal.html \
      || (echo "BUILD ERROR: web/html/terminal.html missing from build context (stale checkout? wrong branch?)" && exit 1); \
    test -x /docker-entrypoint.d/10-sheasy-config.sh \
      || (echo "BUILD ERROR: docker-entrypoint.d/10-sheasy-config.sh missing or not executable" && exit 1); \
    grep -q 'location = /terminal' /etc/nginx/nginx.conf \
      || (echo "BUILD ERROR: nginx.conf missing the /terminal alias (stale nginx.conf)" && exit 1); \
    echo "embed assets present: terminal.html, entrypoint, /terminal alias OK"