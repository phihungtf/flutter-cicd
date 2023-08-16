# Use the official Jenkins image as the base image
FROM jenkins/jenkins:lts

# Use root user to install software
USER root

ENV DEBIAN_FRONTEND noninteractive

ENV ANDROID_HOME      /opt/android-sdk-linux
ENV ANDROID_SDK_HOME  ${ANDROID_HOME}
ENV ANDROID_SDK_ROOT  ${ANDROID_HOME}
ENV ANDROID_SDK       ${ANDROID_HOME}

ENV PATH "${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/cmdline-tools/tools/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/tools/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/build-tools/30.0.3"
ENV PATH "${PATH}:${ANDROID_HOME}/platform-tools"
ENV PATH "${PATH}:${ANDROID_HOME}/emulator"
ENV PATH "${PATH}:${ANDROID_HOME}/bin"

RUN dpkg --add-architecture i386 && \
    apt-get update -yqq && \
    apt-get install -y curl expect git libc6:i386 libgcc1:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 wget unzip vim && \
    apt-get clean

RUN groupadd android && useradd -d /opt/android-sdk-linux -g android android

COPY tools /opt/tools
COPY licenses /opt/licenses

WORKDIR /opt/android-sdk-linux

RUN /opt/tools/entrypoint.sh built-in

RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmdline-tools;latest"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;30.0.3"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platform-tools"

RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-33"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-29"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-31"
# NOTE: Add more platform versions here if you need.

RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "system-images;android-33;google_apis;x86_64"

RUN git config --global --add safe.directory '*'

# Set up Flutter environment variables
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=${FLUTTER_HOME}/bin:${PATH}

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME}
RUN ${FLUTTER_HOME}/bin/flutter doctor

RUN chown -R jenkins:jenkins ${FLUTTER_HOME}

RUN chmod +w -R /opt/android-sdk-linux

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential curl && \
    apt-get clean

# Install ruby-dev
RUN apt-get install -y ruby-dev

# Install rbenv
RUN apt install rbenv -y

# Install Bundler
RUN gem install bundler

# Install Fastlane
RUN gem install fastlane -NV