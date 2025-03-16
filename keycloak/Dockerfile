FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV KC_VERSION=26.1.3
ENV KC_HOME=/opt/keycloak-${KC_VERSION}
ENV KC_DOWNLOAD=https://github.com/keycloak/keycloak/releases/download/${KC_VERSION}/keycloak-${KC_VERSION}.zip

# Install Dependencies
RUN apt-get update -qq
RUN apt-get install -qq -y curl unzip

# Install Amazon Corretto 17 (AWS Java 17 for ARM)
RUN curl -fsSL https://apt.corretto.aws/corretto.key | tee /usr/share/keyrings/corretto-keyring.asc
RUN echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.asc] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list
RUN apt-get update -qq
RUN apt-get install -qq -y java-17-amazon-corretto-jdk

# Set Java Environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Verify Java Installation
RUN java -version

# Download and Install Keycloak
RUN curl -fsSL ${KC_DOWNLOAD} -o /tmp/keycloak.zip
RUN unzip /tmp/keycloak.zip -d /opt/
RUN rm /tmp/keycloak.zip
RUN chmod +x ${KC_HOME}/bin/kc.sh

WORKDIR ${KC_HOME}
EXPOSE 8080

ENV KC_BOOTSTRAP_ADMIN_USERNAME=admin
ENV KC_BOOTSTRAP_ADMIN_PASSWORD=admin

CMD ["bin/kc.sh", "start-dev"]