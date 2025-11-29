# Production optimized Node.js image
FROM node:18-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory and user
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production && npm cache clean --force

# Copy application code
COPY worker.js ./

# Create logs directory
RUN mkdir -p logs && chown -R nodejs:nodejs /app
USER nodejs

# Environment variables
ENV NODE_ENV=production
ENV SERVICE_NAME="Demo Worker Service"
ENV TASK_INTERVAL="*/30 * * * * *"
ENV LOG_LEVEL=info

# Labels for container management
LABEL service.type="worker"
LABEL service.name="demo-worker"
LABEL service.version="1.0.0"
LABEL maintainer="container-platform-team"

# Health check (check if process is still running)
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD pgrep -f "node worker.js" > /dev/null || exit 1

# Start application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "worker.js"]