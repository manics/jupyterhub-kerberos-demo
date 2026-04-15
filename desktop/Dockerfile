FROM ghcr.io/manics/jupyter-desktop-mate:latest

USER root

# Install Kerberos client
RUN apt-get update && apt-get install -y \
    krb5-user \
    && rm -rf /var/lib/apt/lists/*

COPY jupyterhub/krb5.conf /etc/krb5.conf
ENV KRB5_CONFIG=/etc/krb5.conf

RUN mkdir -p /etc/firefox/policies
COPY desktop/policies.json /etc/firefox/policies/policies.json

USER $NB_UID

# Create a desktop shortcut for JupyterHub
RUN mkdir -p ~/Desktop && \
    printf "[Desktop Entry]\nVersion=1.0\nType=Application\nName=JupyterHub\nExec=firefox http://hub.example.org:8000\nIcon=firefox\nTerminal=false\n" > ~/Desktop/jupyterhub.desktop && \
    chmod +x ~/Desktop/jupyterhub.desktop
