# Use an official Nginx image as the base image
FROM nginx:alpine

# Set the working directory in the container
WORKDIR /usr/share/nginx/html

# Copy the application files to the container
COPY . .

LABEL org.opencontainers.image.source=https://github.com/cinderl/clock
LABEL org.opencontainers.image.description="A lightweight, zero-dependency digital clock web application designed for both desktop and mobile devices. This app features real-time updates, customizable settings, and offline support."
LABEL org.opencontainers.image.licenses=MIT

# Expose port 80 to make the app accessible
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]