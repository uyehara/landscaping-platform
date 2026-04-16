FROM node:20-alpine AS builder

WORKDIR /app

RUN npm install

COPY . .
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 api

COPY --from=builder --chown=api:api /app/dist ./dist
COPY --from=builder --chown=api:api /app/package*.json ./

USER api

EXPOSE 3001

CMD ["node", "dist/index.js"]
