FROM ghcr.io/openhundun/ubuntu:24
COPY --from=docker.io/library/eclipse-temurin:21-jdk /opt/java/openjdk /opt/jdk
ENV JAVA_HOME="/opt/jdk"
ENV PATH="/opt/jdk/bin:${PATH}"
CMD ["java", "-version"]
