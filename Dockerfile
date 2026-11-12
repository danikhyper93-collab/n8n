FROM n8nio/n8n:2.47.5

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER node

EXPOSE 5678

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
