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
| `epassword`    | AES-256-GCM encrypted password (see below)  | -            |

*Notes:*
- `host` is mandatory if `connect` is `"true"` (or not provided).
- If `connect` is `"false"`, the connection will not auto-initiate, but the provided connection data will be filled in the connection form.

### Embedding ssheasy in another web app

`embed=1` hides the navbar, connection form, file browser, history list, and
footer so ssheasy fits inside an iframe. When the URL omits the `user` or
`password`, ssheasy prompts for them directly in the terminal (password input
is masked, Ctrl-C cancels) — useful when the parent app supplies the host from
context but not the secret. This terminal prompting also works outside embed
mode for any `/connect` URL with a blank user or password.

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

### Encrypted password parameter (`epassword`)

Putting a plaintext `password=` in the URL leaks it to browser history,
referrer headers, server logs, and screenshots. `epassword` accepts an
AES-256-GCM ciphertext instead. Both ssheasy and the parent app share a
32-byte symmetric key; the URL only contains the ciphertext.

**Threat model:** this protects against URL leakage. It does **not**
protect against an attacker who can fetch `/sheasy-config.js` from
ssheasy's origin — the key is served to the browser so the WASM client
can decrypt. Pair with `nginx` access controls and `frame-ancestors`.

**Setup:**

1. Generate a key once and store it in both places:
   ```
   openssl rand -hex 32
   ```
2. Set `SSHEASY_DECRYPT_KEY` on the ssheasy `web` container (see
   `docker-compose.yaml`). The entrypoint writes it to
   `/usr/share/nginx/html/sheasy-config.js` on container start.
3. Configure the same key on the parent app side.

**Wire format:** `epassword = base64( iv(12 bytes) || ciphertext || tag(16 bytes) )`.
Standard or URL-safe base64 both work.

**PHP (Zabbix side):**
```php
$key = hex2bin(getenv('SSHEASY_DECRYPT_KEY')); // 32 raw bytes
$iv  = random_bytes(12);
$tag = '';
$ct  = openssl_encrypt(
    $password, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $iv, $tag
);
$epassword = rtrim(strtr(base64_encode($iv . $ct . $tag), '+/', '-_'), '=');
$url = "/connect?host=$host&user=$user&epassword=$epassword&embed=1";
```

**Browser side:** ssheasy decodes the parameter, splits off the IV and
tag, and decrypts via `crypto.subtle.decrypt({name:'AES-GCM', iv}, ...)`
before calling `initConnection`. If `SSHEASY_DECRYPT_KEY` is unset or
decryption fails, the user sees an error and the connection is not
attempted.


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
