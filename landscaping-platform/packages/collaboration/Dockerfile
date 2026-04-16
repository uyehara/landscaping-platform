FROM node:20-alpine AS builder

WORKDIR /app

RUN npm install

COPY . .
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 collab

COPY --from=builder --chown=collab:collab /app/dist ./dist
COPY --from=builder --chown=collab:collab /app/package*.json ./
COPY --from=builder --chown=collab:collab /app/node_modules ./node_modules

USER collab

EXPOSE 1234

CMD ["node", "dist/index.js"]
