FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy the entire project folder into the container
COPY project/ ./ 

# Install dependencies inside container
RUN npm ci

# Set default command
CMD ["npm", "test", "--", "--runInBand"]
