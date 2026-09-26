FROM grafana/grafana:11.1.0

# Copy provisioning configs
COPY provisioning/ /etc/grafana/provisioning/

# Copy dashboard JSONs
COPY dashboards/ /var/lib/grafana/dashboards/

# Copy entrypoint script để inject env vars vào datasource config
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh

USER grafana

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
