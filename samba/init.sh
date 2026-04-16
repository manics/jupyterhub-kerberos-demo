#!/bin/bash
set -e

# Path to smb.conf
SMB_CONF="/etc/samba/smb.conf"

if [ ! -f "$SMB_CONF" ]; then
    echo "Samba not provisioned. Initializing..."
    
    # Temporarily remove symlinks from the base image
    rm -rf /etc/samba /var/lib/samba /var/log/samba
    
    echo "Provisioning domain EXAMPLE.ORG in /tmp/provision..."
    mkdir -p /tmp/provision

    # Workaround for rootless Podman: Samba maps the Administrator SID to UID 3000000 by default.
    # We test if the container allows assigning high UIDs. If it fails, we assume a rootless
    # environment (which typically only maps UIDs 0-65535) and patch the ID map to use a lower range.
    touch /tmp/uid_test
    if ! chown 3000000:3000000 /tmp/uid_test 2>/dev/null; then
        echo "High UIDs not supported (rootless container detected). Applying ID map workaround..."
        sed -i 's/3000000/3000/g; s/4000000/40000/g' /usr/share/samba/setup/idmap_init.ldif || true
    else
        echo "High UIDs supported. Using default Samba ID mappings."
    fi
    rm -f /tmp/uid_test

    PROVISION_ARGS=(
        "--use-rfc2307"
        "--realm=EXAMPLE.ORG"
        "--domain=EXAMPLE"
        "--server-role=dc"
        "--dns-backend=SAMBA_INTERNAL"
        "--adminpass=Password123!"
        "--targetdir=/tmp/provision"
        # Disable deprecated encryption types
        "--option=kdc default domain supported enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96"
        "--option=kdc supported enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96"
    )

    # Workaround for xattr restrictions: test if we can write to the security namespace
    touch /tmp/xattr_test
    if ! python3 -c "import os; os.setxattr('/tmp/xattr_test', 'security.NTACL', b'test')" 2>/dev/null; then
        echo "System xattrs not supported (rootless container detected). Applying VFS workaround..."
        PROVISION_ARGS+=("--option=vfs objects=dfs_samba4 acl_xattr xattr_tdb" "--option=acl_xattr:ignore system acls=yes")
    else
        echo "System xattrs supported. Using default Samba VFS objects."
    fi
    rm -f /tmp/xattr_test

    samba-tool domain provision "${PROVISION_ARGS[@]}"
    
    echo "Detailed structure of /tmp/provision:"
    find /tmp/provision -maxdepth 3
    
    echo "Moving data to persistent /samba volume..."
    mkdir -p /samba/etc /samba/lib /samba/logs
    
    # Map the output of targetdir to the expected locations
    # Targetdir usually has etc/samba/smb.conf
    if [ -d /tmp/provision/etc/samba ]; then
        cp -av /tmp/provision/etc/samba/. /samba/etc/
    elif [ -f /tmp/provision/etc/smb.conf ]; then
        cp -av /tmp/provision/etc/. /samba/etc/
    fi
    
    # State and private
    [ -d /tmp/provision/state ] && cp -av /tmp/provision/state/. /samba/lib/
    [ -d /tmp/provision/private ] && cp -av /tmp/provision/private /samba/lib/
    
    # Restore symlinks
    rm -rf /etc/samba /var/lib/samba /var/log/samba
    ln -s /samba/etc /etc/samba
    ln -s /samba/lib /var/lib/samba
    ln -s /samba/logs /var/log/samba
    
    echo "Creating test user 'jovyan'..."
    samba-tool user create jovyan "Password123!" --use-username-as-cn
    
    echo "Creating service account for JupyterHub..."
    samba-tool user create hub-service "Password123!" --random-password
    samba-tool spn add HTTP/hub.example.org hub-service
    
    echo "Exporting keytab to /keytabs/hub/HTTP.keytab..."
    samba-tool domain exportkeytab /keytabs/hub/HTTP.keytab --principal=HTTP/hub.example.org
    chmod 644 /keytabs/hub/HTTP.keytab
    
    echo "Exporting keytab to /keytabs/desktop/jovyan.keytab..."
    samba-tool domain exportkeytab /keytabs/desktop/jovyan.keytab --principal=jovyan
    chmod 644 /keytabs/desktop/jovyan.keytab

    # Kerberos config for the Samba server itself
    if [ -f /var/lib/samba/private/krb5.conf ]; then
        cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
    fi
fi

echo "Checking config file..."
ls -l /etc/samba/smb.conf || echo "smb.conf not found at /etc/samba/smb.conf"
ls -l /samba/etc/smb.conf || echo "smb.conf not found at /samba/etc/smb.conf"

echo "Samba DC is ready."
exec /usr/sbin/samba -i
