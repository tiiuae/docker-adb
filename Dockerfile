# Stage 1: Build
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential wget tar xz-utils golang-go perl \
        ca-certificates liblz4-dev libbrotli-dev libpcre2-dev libpcre3-dev libzstd-dev libgtest-dev \
        libusb-1.0.0-dev libssl-dev protobuf-compiler libprotobuf-dev usbutils pkg-config

RUN wget -q --show-progress --progress=bar:force https://cmake.org/files/v3.16/cmake-3.16.3.tar.gz \
    && tar -xvf cmake-3.16.3.tar.gz && rm cmake-3.16.3.tar.gz \
    && cd cmake-3.16.3 \
    && ./configure && make -j 12 && make install \
    && cd ..

ARG RELEASE="34.0.5"
RUN wget -q --show-progress --progress=bar:force https://github.com/nmeum/android-tools/releases/download/${RELEASE}/android-tools-${RELEASE}.tar.xz \
    && tar -xvf android-tools-${RELEASE}.tar.xz && rm android-tools-${RELEASE}.tar.xz \
    && mv android-tools-${RELEASE} android-tools

RUN mkdir android-tools/build && cd android-tools/build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j 12

# Collect shared libraries required by adb
RUN mkdir -p /deps \
    && ldd /android-tools/build/vendor/adb | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /deps/

# Stage 2: Runtime
FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends libusb-1.0.0-dev libssl-dev usbutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /android-tools/build/vendor/adb /usr/local/bin/adb
COPY --from=build /deps /usr/local/lib

RUN ldconfig

RUN adduser --disabled-login --disabled-password adb
USER adb
CMD ["/usr/local/bin/adb", "-a", "nodaemon", "server"]