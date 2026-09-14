FROM ghcr.io/openhundun/ubuntu-jdk:24-17
COPY --from=docker.io/library/maven:3.9.16-eclipse-temurin-17 /usr/share/maven /opt/maven
ENV MAVEN_HOME="/opt/maven"
ENV PATH="/opt/maven/bin:${PATH}"
RUN tee /opt/maven/conf/settings.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<settings>
    <mirrors>
        <mirror>
            <id>aliyun-public</id>
            <mirrorOf>*</mirrorOf>
            <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
        <mirror>
            <id>maven-default-http-blocker</id>
            <mirrorOf>external:http:*</mirrorOf>
            <name>Pseudo repository to mirror external repositories initially using HTTP.</name>
            <url>http://0.0.0.0/</url>
            <blocked>false</blocked>
        </mirror>
    </mirrors>
</settings>
EOF
CMD ["mvn", "-version"]
