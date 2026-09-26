FROM prom/prometheus:v2.53.0

# Copy config và entrypoint
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY entrypoint.sh /entrypoint.sh

# chmod cần root — prom image mặc định chạy root khi build
USER root
RUN chmod +x /entrypoint.sh

VOLUME ["/prometheus"]

EXPOSE 9090

# Script inject env vars vào config rồi exec prometheus
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
