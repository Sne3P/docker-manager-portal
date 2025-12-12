# Multi-stage build for optimization
FROM node:18-alpine AS deps

# Install dependencies only when needed
WORKDIR /app
COPY package*.json ./
RUN npm ci --silent && npm cache clean --force

# Rebuild source code when needed  
FROM node:18-alpine AS builder
WORKDIR /app

# Accept build args
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build application with environment variable
RUN npm run build

# Production image
FROM node:18-alpine AS runner
WORKDIR /app

# Create app user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Change ownership
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["node", "server.js"]