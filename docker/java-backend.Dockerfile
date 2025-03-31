# java-backend.Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . /app
RUN ./gradlew build --no-daemon
CMD ["java", "-jar", "build/libs/app.jar"]
