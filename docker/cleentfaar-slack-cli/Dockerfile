FROM php:8.3-cli-alpine AS builder
RUN apk add --no-cache git
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
RUN git clone --depth 1 https://github.com/cleentfaar/slack-cli.git .
RUN composer install --no-dev --optimize-autoloader

FROM php:8.3-cli-alpine
WORKDIR /app
COPY --from=builder /app /app
ENTRYPOINT ["php", "bin/slack"]
CMD ["--help"]
