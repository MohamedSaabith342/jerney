
# ---- Build stage ----
FROM node:24-alpine3.24 AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY src/ ./src/


# ---- Production stage ----
FROM node:24-alpine3.24 AS production

# Upgrade Alpine packages and install dumb-init
RUN apk upgrade --no-cache && \
    apk add --no-cache dumb-init

# Remove npm because it is not required at runtime
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx

# Create non-root user
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

COPY --chown=appuser:appgroup package.json ./

COPY --from=build --chown=appuser:appgroup \
    /app/node_modules ./node_modules

COPY --chown=appuser:appgroup src/ ./src/

USER appuser

EXPOSE 5000

ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "src/index.js"]
