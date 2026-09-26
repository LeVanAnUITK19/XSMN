FROM grafana/grafana:11.1.0

# Copy provisioning configs
COPY provisioning/ /etc/grafana/provisioning/

# Copy dashboard JSONs
COPY dashboards/ /var/lib/grafana/dashboards/

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh

# Grafana chạy với user grafana (uid 472)
USER grafana

EXPOSE 3000

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
