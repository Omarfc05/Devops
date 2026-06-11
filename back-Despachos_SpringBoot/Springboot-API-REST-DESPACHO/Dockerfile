# ETAPA 1: Build
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ETAPA 2: Runtime
FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app
# Crear un usuario no root para seguridad
RUN groupadd -r spring && useradd -r -g spring spring
COPY --from=build /app/target/*.jar app.jar
USER spring
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]