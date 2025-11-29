# Multi-stage build for optimized Nginx image
FROM nginx:alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy website content
COPY index.html /usr/share/nginx/html/

# Create custom error pages
RUN echo '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>404 - Page Not Found</h1><p>The requested page could not be found.</p></body></html>' > /usr/share/nginx/html/404.html

RUN echo '<!DOCTYPE html><html><head><title>Server Error</title></head><body><h1>500 - Server Error</h1><p>The server encountered an internal error.</p></body></html>' > /usr/share/nginx/html/50x.html

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Labels for container management
LABEL service.type="web"
LABEL service.name="demo-web"
LABEL service.version="1.0.0"
LABEL maintainer="container-platform-team"

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]