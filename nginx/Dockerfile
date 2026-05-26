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