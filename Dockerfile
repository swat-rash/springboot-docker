# Stage 01: Builder
FROM maven:3.6.3-openjdk-8-slim as builder
WORKDIR /app

# Copying source files
COPY . .

RUN mvn clean install \
    && ls -la

# Stage 02: runtime
FROM alpine:3.11.5

RUN apk add --no-cache python3 \
    && python3 -m ensurepip \
    && pip3 install --upgrade pip setuptools \
    && rm -r /usr/lib/python*/ensurepip && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

WORKDIR /app

ENV JAR_FILE=target/hello-world-0.1.0.jar
ENV JAVA_APP_DIR=/app
ENV JAVA_MAJOR_VERSION=8

COPY --from=builder "/app/$JAR_FILE" /app/

RUN apk update \
    && apk add --virtual \
    build-dependencies \
    openjdk8 \
    # please remove once app has shifted to an ORM implementation
    # If removed, to accomplish admin tasks from within container
    # execute `apk add mysql-client` (needs disabling SecurityContext of pod - runAsRoot: true)
    mysql-client \
    redis \
    # required for es admin script execution
    ca-certificates \
    curl 

EXPOSE 80

CMD ["java", "-jar", "hello-world-0.1.0.jar"]
