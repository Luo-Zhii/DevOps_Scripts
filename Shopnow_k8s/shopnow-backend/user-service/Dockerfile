# Stage 1: Build the application
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

# Stage 2: Run the application
FROM openjdk:17-jdk-slim

WORKDIR /app
COPY --from=builder /app/target/user-service-0.0.1-SNAPSHOT.war /app/user-service.war

EXPOSE 5865
ENTRYPOINT exec java -jar /app/user-service.war --spring.config.location=/app/src/main/resources/application.properties
