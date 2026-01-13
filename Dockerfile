# ============ Build Stage ============
FROM node:25-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --include=dev
COPY . .
RUN npm run build

# ============ Runtime Stage ============
FROM node:25-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.cjs ./server.cjs
EXPOSE 8080
CMD ["node","server.cjs"]
