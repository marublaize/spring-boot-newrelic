# Build the application
FROM gradle:jdk17 AS builder

WORKDIR /app

COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .
COPY src src

RUN ./gradlew build

# Run the application
FROM amazoncorretto:17

WORKDIR /app

# Download New Relic Java agent
RUN yum update -y && \
    yum install -y curl unzip && \
    curl -O https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip && \
    unzip newrelic-java.zip && \
    rm newrelic-java.zip

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

CMD ["java", "-javaagent:/app/newrelic/newrelic.jar", "-jar", "app.jar"]