# Build stage
FROM node:16.13.2-alpine as build

# Our working directory
WORKDIR /app

# Install the dependencies
COPY package*.json yarn.lock ./

# Install the dependencies
RUN yarn install

# Copy the entire project directory into the container
COPY . .

# Build the Next.js application
RUN yarn build

# Release step
FROM nginx:1.21.5-alpine as release

# Removing the default Nginx configuration
RUN rm -rf /etc/nginx/conf.d/*

# Built Next.js files from the previous stage to the Nginx server root
COPY --from=build /app/.next /usr/share/nginx/html/

# Custom Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for Nginx
EXPOSE 80

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
