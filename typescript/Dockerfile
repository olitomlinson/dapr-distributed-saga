# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm install

# Copy source code
COPY . .

# Build TypeScript to JavaScript
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy built JavaScript from builder stage
COPY --from=builder /app/dist ./dist

# Expose application port
EXPOSE 8080

# Set environment
ENV NODE_ENV=production

# Start the application
CMD ["node", "dist/index.js"]
