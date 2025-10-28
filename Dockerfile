# Stage 1: Build Stage
FROM node:20-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the work directory
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Stage 2: Production Stage
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy installed modules and application code from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js ./server.js

# Expose the port the app runs on
EXPOSE 8080

# Define the command to run the app
CMD ["npm", "start"]