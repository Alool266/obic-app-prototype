# Made by Dr Ali
# Phase C prep only: build the API image. Do not put secrets here.
# Local Mac still uses Homebrew Postgres + npm run start:dev.

FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3001
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY scripts/docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh
EXPOSE 3001
# DATABASE_URL and JWT secrets come from env at runtime — never baked in.
# Entrypoint applies pending migrations (e.g. durable uploads) before listen.
CMD ["/app/docker-entrypoint.sh"]
