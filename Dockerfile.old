# Use the official Fedora 42 base image
FROM fedora:42

# Set environment variables to non-interactive to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN dnf install -y \
    bash \
    bzip2 \
    ca-certificates \
    clang \
    cmake \
    curl \
    file \
    git \
    gtk3-devel \
    mesa-libGLU \
    ninja-build \
    java-21-openjdk-devel \
    pkg-config \
    unzip \
    which \
    xz \
    zip

# Set up a non-root user
RUN useradd -ms /bin/bash flutteruser
USER flutteruser
WORKDIR /home/flutteruser

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /home/flutteruser/flutter
ENV PATH="/home/flutteruser/flutter/bin:${PATH}"

# Download and install Android SDK command-line tools
RUN mkdir -p /home/flutteruser/android/cmdline-tools && \
    curl -o android_sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip android_sdk.zip -d /home/flutteruser/android/cmdline-tools && \
    mv /home/flutteruser/android/cmdline-tools/cmdline-tools /home/flutteruser/android/cmdline-tools/latest && \
    rm android_sdk.zip

# Set Android environment variables
ENV ANDROID_SDK_ROOT="/home/flutteruser/android"
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Accept Android licenses and install necessary Android components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Run flutter doctor to verify the installation
RUN flutter doctor -v

# Set the working directory for new projects
WORKDIR /home/flutteruser/app

# The default command to run when the container starts
CMD ["/bin/bash"]

