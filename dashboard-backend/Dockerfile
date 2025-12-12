# Multi-stage build for optimization
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies with npm ci for faster, reproducible builds
RUN npm ci --only=production --silent && npm cache clean --force

# Install dev dependencies for build
RUN npm install --only=development --silent

# Copy source code
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install dependencies in one layer for better caching
RUN apk add --no-cache dumb-init wget docker curl bash py3-pip python3 \
    gcc python3-dev musl-dev linux-headers libffi-dev openssl-dev cargo

# Install Azure CLI in virtual environment with optimized flags
RUN python3 -m venv /opt/azure-cli && \
    /opt/azure-cli/bin/pip install --upgrade --no-cache-dir pip && \
    /opt/azure-cli/bin/pip install --no-cache-dir azure-cli && \
    ln -s /opt/azure-cli/bin/az /usr/local/bin/az && \
    rm -rf /tmp/* /var/cache/apk/*

# Create app user for security and add to docker group
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    adduser nodejs docker

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies with optimizations
RUN npm ci --only=production --silent && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Create logs directory
RUN mkdir -p logs && chown nodejs:nodejs logs

# For Docker socket access, we need to run as root or ensure proper group permissions
# For development, we'll run as root for Docker access
# In production, you should configure proper group permissions
# USER nodejs

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })" || exit 1

# Start application with dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]