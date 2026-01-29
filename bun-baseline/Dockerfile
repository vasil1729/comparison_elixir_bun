FROM oven/bun:1-alpine

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN bun install --production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start server
CMD ["bun", "run", "server.ts"]
