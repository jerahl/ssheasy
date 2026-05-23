# ssheasy

Source repositorty of the online ssh, sftp client [ssheasy.com](https://ssheasy.com)

![SSH and open tunnel in new tab](./doc/tunnel.gif)

## Building, running locally

`docker-compose up`

This will compile the wasm ssh, sftp client, the proxy component that proxies tcp connections for the client running in the browser through websocket and sets up nginx server serving the web frontend.
Additionaly prometheus and grafana is set up as well to monitor the connections proxied. An sshd is also started in a container for testing.

### connect endpoint

Use `/connect?host=HOST&port=PORT&user=USER&password=PASSWORD` for initiating connection right away after opening the url.


| Parameter      | Description                                 | Default Value |
|----------------|---------------------------------------------|--------------|
| `host`         | SSH server hostname or IP address           | –            |
| `port`         | SSH server port                             | 22           |
| `user`         | SSH username                                | –            |
| `password`     | SSH password                                | –            |
| `pk`           | Private key (as string, for key auth)       | –            |
| `webauthnKey`  | WebAuthn key ID (for WebAuthn auth)         | -1           |
| `connect`      | Whether to auto-connect (`"true"`/`"false"`) | "true"      |
| `embed`        | Embed mode (`"1"` strips chrome for iframing) | -          |
| `readonly`     | Drop user keystrokes except Ctrl-C (`"1"`)  | -            |
| `origin`       | Allowed parent origin for postMessage       | -            |
| `cmd`          | Base64-encoded command to run on connect    | -            |

*Notes:*
- `host` is mandatory if `connect` is `"true"` (or not provided).
- If `connect` is `"false"`, the connection will not auto-initiate, but the provided connection data will be filled in the connection form.

### Embedding ssheasy in another web app

`embed=1` hides the navbar, file browser, history list, and footer so ssheasy
fits inside an iframe. The host/port/user fields stay visible (read-only) when
credentials are missing so an operator can type their password — useful when
the parent app supplies the host/user from context but not the secret.

Set `origin` to the parent window's origin to enable a postMessage bridge:

| Direction         | Message                                     | Meaning |
|-------------------|---------------------------------------------|---------|
| iframe → parent   | `{type:"status", state:"loaded"}`           | Page loaded, ready for messages |
| iframe → parent   | `{type:"status", state:"connected", msg}`   | SSH session is up |
| iframe → parent   | `{type:"status", state:"disconnected", msg}`| Connection dropped |
| iframe → parent   | `{type:"status", state:"error", msg}`       | Error shown to user |
| iframe → parent   | `{type:"pong"}`                             | Reply to a `ping` |
| parent → iframe   | `{type:"run", cmd:"show version"}`          | Run command (bypasses `readonly`) |
| parent → iframe   | `{type:"interrupt"}`                        | Send Ctrl-C |
| parent → iframe   | `{type:"ping"}`                             | Liveness check |

Messages from origins other than `origin` are ignored. Configure nginx
`frame-ancestors` (see `nginx/nginx.conf`) so browsers will only embed
ssheasy from the parent app's origin.


## Testing

For testing docker-compose sets up an sshd in a separate container. After starting up the stack with `docker-compose up` open http://localhost:8080 in your browser and use the host testssh with user root and password root.

### Testing Webauthn

After building the project and creating a webauthn key copy the displayed public key to the `ssh_conf/authorized_keys` file and start the testopenssh service in the docker compose if you have not started it yet. User name is `linuxserver.io` hostname: `testopenssh` port: `2222`.  

## Project structure

* nginx: web server config, Dockerfile for building the wasm ssh/sftp client
* proxy: golang proxy service for tunneling tcp connections through websocket
* web: source of the ssh, sftp wasm client, and the httml for the frontend

### Filemanager UI

The filemanager is based on [forked version](https://github.com/hullarb/angular-filemanager)) of [angular-filemanager](https://github.com/joni2back/angular-filemanager). The fork replaces the backend api calls with calls to the wasm sftp client.
The fork has to be built separately and copied to the *web/html/node_modules* directory.
