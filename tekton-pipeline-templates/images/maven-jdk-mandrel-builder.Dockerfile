FROM centos:centos8
ARG MAVEN_VERSION=3.6.3
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
ARG JAVA_PACKAGE=java-11-openjdk-headless
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG USER_HOME_DIR="/maven"
ARG WORK_DIR="/workspace"
ARG GRAALVM_DIR=/opt/mandral
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'
RUN dnf install -y dnf-plugins-core \
    && dnf config-manager --set-enabled PowerTools \
    && dnf install -y glibc-devel zlib-devel gcc libffi-devel libstdc++-devel libstdc++-static openssl curl ca-certificates git tar which ${JAVA_PACKAGE} \
    && dnf update -y \
    && dnf clean all \
    && mkdir -p ${USER_HOME_DIR} \
    && chown 1001 ${USER_HOME_DIR} \
    && chmod "g+rwX" ${USER_HOME_DIR} \
    && chown 1001:root ${USER_HOME_DIR} \
    && mkdir -p ${WORK_DIR} \
    && chown 1001 ${WORK_DIR} \
    && chmod "g+rwX" ${WORK_DIR} \
    && chown 1001:root ${WORK_DIR} \
    && echo "securerandom.source=file:/dev/urandom" >> /etc/alternatives/jre/lib/security/java.security \
    && mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && rm -f /tmp/apache-maven.tar.gz \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && mkdir -p ${GRAALVM_DIR} \
    && curl -fsSL -o /tmp/mandrel-java11-linux-amd64-20.1.0.2.Final.tar.gz https://github.com/graalvm/mandrel/releases/download/mandrel-20.1.0.2.Final/mandrel-java11-linux-amd64-20.1.0.2.Final.tar.gz \
    && tar xzf /tmp/mandrel-java11-linux-amd64-20.1.0.2.Final.tar.gz -C ${GRAALVM_DIR} --strip-components=1
ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG="${USER_HOME_DIR}/.m2"
ENV GRAALVM_HOME=${GRAALVM_DIR}

VOLUME ${WORK_DIR}

