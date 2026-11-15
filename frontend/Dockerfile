# ---- Build stage ----
FROM node:20-alpine3.22 AS build

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy frontend source code
COPY . .

# Build production frontend
RUN npm run build


# ---- Production stage ----
FROM nginx:stable-alpine3.24 AS production

# Upgrade installed Alpine packages
RUN apk update && apk upgrade --no-cache

# Remove default Nginx configuration and website
RUN rm -rf /etc/nginx/conf.d/default.conf \
    /usr/share/nginx/html/*

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled frontend files
COPY --from=build /app/dist /usr/share/nginx/html

# Prepare permissions for non-root Nginx
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Run as non-root
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
