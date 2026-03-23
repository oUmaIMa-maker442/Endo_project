FROM openjdk:17-jdk-slim AS builder
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O /tmp/cmdtools.zip && \
    unzip -q /tmp/cmdtools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm /tmp/cmdtools.zip

RUN yes | sdkmanager --licenses > /dev/null 2>&1
RUN sdkmanager "platforms;android-33" "build-tools;33.0.2" "platform-tools"

WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ./gradlew assembleDebug --no-daemon

FROM python:3.11-alpine
WORKDIR /apk
COPY --from=builder /app/app/build/outputs/apk/debug/app-debug.apk .
EXPOSE 8080
CMD ["python3", "-m", "http.server", "8080"]