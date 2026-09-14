FROM ghcr.io/openhundun/debian:13
COPY --from=docker.io/library/eclipse-temurin:25-jdk /opt/java/openjdk /opt/jdk
ENV JAVA_HOME="/opt/jdk"
ENV PATH="/opt/jdk/bin:${PATH}"
CMD ["java", "-version"]
