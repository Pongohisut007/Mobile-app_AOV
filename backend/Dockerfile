# syntax=docker/dockerfile:1.7

FROM node:24.21.0-alpine AS base

WORKDIR /app

ENV NPM_CONFIG_UPDATE_NOTIFIER=false \
  NPM_CONFIG_FUND=false


# =========================================================
# Build dependencies
# =========================================================

FROM base AS build-deps

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
  npm ci


# =========================================================
# Build
# =========================================================

FROM base AS build

COPY --from=build-deps /app/node_modules ./node_modules

COPY package.json package-lock.json ./
COPY . .

RUN npm run build


# =========================================================
# Production dependencies
# =========================================================

FROM base AS production-deps

ENV NODE_ENV=production

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
  npm ci \
  --omit=dev \
  --no-audit \
  --fund=false


# =========================================================
# Runtime
# =========================================================

FROM base AS production

ENV NODE_ENV=production

COPY --from=production-deps \
  --chown=node:node \
  /app/node_modules \
  ./node_modules

COPY --from=build \
  --chown=node:node \
  /app/dist \
  ./dist

COPY --chown=node:node \
  package.json \
  package-lock.json \
  ./

RUN mkdir -p /app/uploads \
  && chown node:node /app/uploads

USER node

EXPOSE 3000

CMD ["node", "dist/src/main.js"]