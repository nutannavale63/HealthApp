# Stage 1: Build React App
FROM node:18-alpine AS build

WORKDIR /app

ENV NODE_OPTIONS="--openssl-legacy-provider"

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Serve with Apache
FROM httpd:2.4-alpine

RUN rm -rf /usr/local/apache2/htdocs/*

COPY --from=build /app/build /usr/local/apache2/htdocs/

EXPOSE 80

CMD ["httpd-foreground"]

