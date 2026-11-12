FROM n8nio/n8n:2.47.5

USER root
RUN apk add --no-cache python3
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER node

EXPOSE 5678

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
