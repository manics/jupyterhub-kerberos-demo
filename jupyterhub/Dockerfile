FROM quay.io/jupyterhub/jupyterhub:latest

# Install Kerberos client and build dependencies
RUN apt-get update && apt-get install -y \
    krb5-user \
    libkrb5-dev \
    gcc \
    git \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install kerberosauthenticator and jupyterlab
# Requires fixes from https://github.com/jupyterhub/kerberosauthenticator/pull/13
RUN pip install --no-cache-dir \
    jupyterlab \
    pykerberos \
    jupyterhub-kerberosauthenticator==1.0.0rc1

# Copy configuration
COPY jupyterhub/jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY jupyterhub/krb5.conf /etc/krb5.conf

# Set environment variables
ENV KRB5_CONFIG=/etc/krb5.conf
ENV KRB5_KTNAME=/etc/jupyterhub/HTTP.keytab

CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
