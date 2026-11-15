
# ---- Build stage ----
FROM node:20-alpine3.22 AS build

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --omit=dev && npm cache clean --force


# ---- Production stage ----
FROM node:20-alpine3.22 AS production

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install dumb-init
RUN apk add --no-cache dumb-init=1.2.5-r3

WORKDIR /app

# Copy package information
COPY --chown=appuser:appgroup package.json ./

# Copy production dependencies
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules

# Copy application source
COPY --chown=appuser:appgroup src/ ./src/

# Run as non-root
USER appuser

EXPOSE 5000

# Handle signals correctly
ENTRYPOINT ["dumb-init", "--"]

# Start backend
CMD ["node", "src/index.js"]

