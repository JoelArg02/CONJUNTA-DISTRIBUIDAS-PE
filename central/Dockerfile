FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copiar solo pom.xml primero para cache de dependencias
COPY pom.xml .

# Descargar dependencias (se cachea en esta capa)
RUN mvn -DskipTests dependency:go-offline

# Copiar código fuente y compilar
COPY src ./src
RUN mvn -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app

# Copiar el JAR construido
COPY --from=build /app/target/*.jar app.jar

# Exponer puerto
EXPOSE 8761

# Configurar JVM para contenedor
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
