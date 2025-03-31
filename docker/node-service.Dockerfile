# docker/node-service.Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose port (match your app.js port)
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
