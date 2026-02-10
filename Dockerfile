FROM node:22-bookworm

ARG OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"
ARG OPENCLAW_REF="v2026.2.9"
ARG OPENCLAW_DOCKER_APT_PACKAGES=""

ENV BUN_INSTALL="/usr/local/bun"
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
ENV NODE_ENV="production"
ENV HOME="/home/node"
ENV TERM="xterm-256color"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      openssh-client \
      tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN curl -fsSL https://bun.sh/install | bash
RUN corepack enable

WORKDIR /app

RUN git clone --depth 1 --branch "${OPENCLAW_REF}" "${OPENCLAW_REPO}" /app

RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

RUN pnpm install --frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

RUN rm -rf /app/.git /app/.github /app/.agent /app/.agents

RUN mkdir -p /home/node/.openclaw /home/node/.openclaw/workspace && \
    chown -R node:node /app /home/node

USER node

EXPOSE 18789 18790

ENTRYPOINT ["tini", "--"]
CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured", "--bind", "lan", "--port", "18789"]
