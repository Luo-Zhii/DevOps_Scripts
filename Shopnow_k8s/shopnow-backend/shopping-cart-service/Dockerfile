# Stage 1: Build the application
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

# Stage 2: Run the application
FROM openjdk:17-jdk-slim

WORKDIR /app
COPY --from=builder /app/target/shopping-cart-service-0.0.1-SNAPSHOT.war /app/cart-service.war

EXPOSE 5863
ENTRYPOINT exec java -jar /app/cart-service.war --spring.config.location=/app/src/main/resources/application.properties
