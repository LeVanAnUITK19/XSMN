FROM prom/prometheus:v2.53.0

# Copy config
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Copy alert rules nếu có
# COPY rules/ /etc/prometheus/rules/

# Data directory (mount volume ở đây để persist)
VOLUME ["/prometheus"]

EXPOSE 9090

ENTRYPOINT ["/bin/prometheus"]
CMD [ \
  "--config.file=/etc/prometheus/prometheus.yml", \
  "--storage.tsdb.path=/prometheus", \
  "--storage.tsdb.retention.time=${PROMETHEUS_RETENTION:-7d}", \
  "--web.enable-lifecycle", \
  "--web.console.libraries=/usr/share/prometheus/console_libraries", \
  "--web.console.templates=/usr/share/prometheus/consoles" \
]
