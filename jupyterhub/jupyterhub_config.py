import os

c = get_config()

# Configure Kerberos Authenticator
# from kerberosauthenticator import KerberosAuthenticator
from kerberosauthenticator import KerberosLocalAuthenticator

c.JupyterHub.authenticator_class = KerberosLocalAuthenticator

# For easy testing use local users inside the hub container instead of
# spawning separate containers which requires mounting the docker socket
c.KerberosLocalAuthenticator.create_system_users = True

c.KerberosAuthenticator.keytab = "/etc/jupyterhub/HTTP.keytab"
c.KerberosAuthenticator.service_name = "HTTP"

# Allow any authenticated user
c.Authenticator.allow_all = True

c.JupyterHub.ip = "0.0.0.0"
# c.JupyterHub.hub_ip = '0.0.0.0'

c.JupyterHub.log_level = "DEBUG"
