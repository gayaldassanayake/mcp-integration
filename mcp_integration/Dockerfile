FROM eclipse-temurin:25-jre
COPY target/bin/mcp_integration.jar /app/app.jar
USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseSerialGC", "-XX:MaxRAMPercentage=70", "-Duser.timezone=UTC", "-Djava.io.tmpdir=/tmp", "-jar", "/app/app.jar"]
