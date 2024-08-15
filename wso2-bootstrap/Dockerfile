ARG DEBIAN_TAG
# Use Debian
FROM debian:${DEBIAN_TAG}

ENV SOAPUI_VERSION 5.7.0
ENV SOAPUI_URL https://s3.amazonaws.com/downloads.eviware/soapuios/${SOAPUI_VERSION}/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz
ENV JDK_URL https://corretto.aws/downloads/resources/11.0.24.8.1/java-11-amazon-corretto-jdk_11.0.24.8-1_amd64.deb

# Update system and install necessary utilities
RUN apt-get update && \
  apt-get install --no-install-recommends --yes curl ca-certificates java-common wget curl tar

# Download the most recent image of Amazon Carreto 11
RUN wget ${JDK_URL} && \
  dpkg --install java-11-amazon-corretto-jdk_11.0.24.8-1_amd64.deb

# Download and install SoapUI
RUN wget ${SOAPUI_URL} &&\
  tar -xvf SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz -C /opt &&\
  ln -s /opt/SoapUI-${SOAPUI_VERSION} /opt/SoapUI

# Add SoapUI to the PATH
ENV PATH ${PATH}:/opt/SoapUI/bin
WORKDIR /opt/SoapUI/bin

# -----------------------------------
# Set Docker image build arguments
# -----------------------------------
ARG USER=soapuser
ARG USER_ID=1100
ARG USER_GROUP=soapgroup
ARG USER_GROUP_ID=1100
ARG USER_HOME=/home/${USER}

RUN <<EOF
groupadd -g ${USER_GROUP_ID} ${USER_GROUP} &&
useradd --create-home --home-dir ${USER_HOME} --no-log-init -g ${USER_GROUP_ID} -u ${USER_ID} ${USER}
EOF

# Copy required scripts to user home directory
COPY --chown=${USER}:${USER_GROUP} docker-entrypoint.sh ${USER_HOME}/
COPY --chown=${USER}:${USER_GROUP} wso2is-init-project.xml ${USER_HOME}/
COPY --chown=${USER}:${USER_GROUP} server.properties ${USER_HOME}/

RUN <<EOF
chmod 744 ${USER_HOME}/docker-entrypoint.sh
chmod 644 ${USER_HOME}/wso2is-init-project.xml
chmod 644 ${USER_HOME}/server.properties
EOF

# Set the user and work directory
USER ${USER_ID}
WORKDIR ${USER_HOME}

ENTRYPOINT ["/home/soapuser/docker-entrypoint.sh"]
