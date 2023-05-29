# Build stage
FROM node:16.13.2-alpine as build

WORKDIR /app

COPY package.json yarn.lock ./

RUN yarn install

COPY . .

RUN yarn build

# Release step
FROM nginx:1.21.5-alpine as release

COPY --from=build /app/.next /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
