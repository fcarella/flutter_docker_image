# Use the official Fedora 42 base image
FROM fedora:42

# Install necessary dependencies
RUN dnf install -y \
    bash bzip2 ca-certificates clang cmake curl file git gtk3-devel \
    mesa-libGLU ninja-build java-21-openjdk-devel pkg-config unzip which xz zip

# Set up a non-root user
RUN useradd -ms /bin/bash flutteruser
USER flutteruser
WORKDIR /home/flutteruser

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /home/flutteruser/flutter
ENV PATH="/home/flutteruser/flutter/bin:${PATH}"

# --- IMPORTANT UPDATE ---
# Force Flutter to upgrade itself to the latest stable version during the build.
RUN flutter upgrade

# Download and install Android SDK command-line tools
RUN mkdir -p /home/flutteruser/android/cmdline-tools && \
    curl -o android_sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip android_sdk.zip -d /home/flutteruser/android/cmdline-tools && \
    mv /home/flutteruser/android/cmdline-tools/cmdline-tools /home/flutteruser/android/cmdline-tools/latest && \
    rm android_sdk.zip

# Set Android environment variables
ENV ANDROID_SDK_ROOT="/home/flutteruser/android"
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Accept licenses and install a broad set of Android components to prevent runtime downloads
RUN yes | sdkmanager --licenses && \
    sdkmanager --update && \
    sdkmanager "platform-tools" \
               "platforms;android-34" "build-tools;34.0.0" \
               "platforms;android-35" "build-tools;35.0.0" \
               "ndk-bundle"

# Run flutter doctor to verify the installation
RUN flutter doctor -v

# Set the working directory for new projects
WORKDIR /home/flutteruser/app

# The default command to run when the container starts
CMD ["/bin/bash"]
```**What's new?**
*   `RUN flutter upgrade`: This is the crucial new line. It tells Docker to update the Flutter SDK to the latest stable version *at the time the image is built*. This will give us the modern command-line flags.
*   We've also added more Android SDK components to prevent future hangs.

---

### Part 2: A New, Windows-Specific `docker-compose.yml`

This file uses a different approach. Instead of trying to connect ADB, it explicitly opens the specific ports that the Flutter debugger needs. This is more reliable on Windows.

**Create a new file named `docker-compose.windows.yml`:**

```yaml
# docker-compose.windows.yml
# A dedicated configuration for Windows 11 hosts.
version: '3.8'

services:
  flutter-dev:
    # IMPORTANT: We now build the image from our local Dockerfile
    # instead of pulling it from Docker Hub.
    build:
      context: .
      dockerfile: Dockerfile

    # Use a custom container name for easier management
    container_name: flutter_dev_windows

    stdin_open: true
    tty: true
    working_dir: /home/flutteruser/app

    # Mount the local project folder into the container's workspace
    volumes:
      - .:/home/flutteruser/app

    # --- Windows Networking Configuration ---
    # Expose the Flutter VM Service port and a range for other services.
    # This allows the debugger to connect from the host.
    ports:
      - "8181:8181" # Port for the Dart VM Service
      - "9100-9110:9100-9110" # A range for other potential services