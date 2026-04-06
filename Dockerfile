FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/app.jar /app/app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
