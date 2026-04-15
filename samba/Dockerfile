FROM ghcr.io/manics/k8tre-samba-dc:main

USER root

# Install bash and krb5
RUN apk add --no-cache bash krb5

# Remove the symlinks from the base image
RUN rm -rf /etc/samba /var/lib/samba /var/log/samba

COPY init.sh /init.sh
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]
