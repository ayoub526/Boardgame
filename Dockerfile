# ===== Build Stage =====
FROM maven:3.9.9-eclipse-temurin-11 AS build
WORKDIR /app

# Copy pom.xml to enable caching
COPY pom.xml .

# Download dependencies
RUN mvn -B -q -DskipTests dependency:go-offline

# Copy source
COPY src ./src

# Build jar
RUN mvn clean package -DskipTests

# ===== Runtime Stage =====
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app

# Copy built JAR
COPY --from=build /app/target/*.jar app.jar

# Expose Spring Boot port
EXPOSE 8080

# Start the app
ENTRYPOINT ["java", "-jar", "app.jar"]
