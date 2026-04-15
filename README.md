# JupyterHub Kerberos Docker Compose Demo

A self-contained example of JupyterHub configured with Kerberos authentication using a Samba-based Domain Controller (DC).

## Quick Start

### Running

1. Run `docker compose up -d`
2. Run `docker compose logs -f` in another terminal to monitor startup
3. Wait, the Samba DC may take about 30 seconds to provision the domain on its first run
4. Connect to the virtual VNC desktop vnc://localhost:5901
5. Start a terminal
6. Check you now have a ticket automatically created: `klist`
7. Launch Firefox, then go to http://hub.example.org:8000
8. You should be able to login automatically with Kerberos and spawn a server
9. If you have problems try connecting to JupyterHub using curl:
   ```sh
   docker compose exec -it jupyterhub bash
   # Obtain a Kerberos ticket
   kinit jovyan@EXAMPLE.ORG  # Password: Password123!
   # Test authentication via the Hub login endpoint
   curl -v --negotiate -u : http://hub.example.org:8000/hub/kerberos_login
   ```
   A successful test will result in a `302 Found` redirect to `/hub/spawn`, indicating the Hub has accepted your Kerberos ticket.

## Implementation notes

### Samba DC

- Kerberos Key Distribution Center (KDC) and Domain Controller.
- Hostname: `samba.example.org`
- Realm: `EXAMPLE.ORG`
- `samba/init.sh`: initialization script uses `samba-tool` to setup the domain, and creates keytabs for `HTTP` (the JupyterHub service) and the `jovyan` user.

### JupyterHub

- JupyterHub web application requiring Kerberos authentication.
- Hostname: `hub.example.org`

### Shared Volumes

Separate Docker volumes are used to share keytabs between containers:

- `hub-keytab`: Mounts to `/keytabs/hub` in the `samba` container and read-only to `/etc/jupyterhub` in the `jupyterhub` container to provide access to the `HTTP.keytab`.
- `desktop-keytab`: Mounts to `/keytabs/desktop` in the `samba` container and read-only to `/etc/desktop` in the `desktop` container to provide access to the test user's keytab `jovyan.keytab` for automatic Kerberos login.

### External browsers

If you want to connect from your own browser instead of the VNC desktop you will need to modify `docker-compose.yaml` to expose the samba server, and setup your local DNS resolution to resolve `hub.example.org` and `samba.example.org`.
