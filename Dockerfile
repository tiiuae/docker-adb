FROM ubuntu:22.04

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

# Clean up build dependencies
RUN rm -rf cmake-3.16.3 \
    && apt-get remove --purge -y build-essential wget xz-utils golang-go perl liblz4-dev \
        libbrotli-dev libpcre2-dev libpcre3-dev libzstd-dev libgtest-dev libusb-1.0.0-dev libssl-dev \
        protobuf-compiler libprotobuf-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sr android-tools/build/vendor/adb /usr/local/bin/adb

RUN adduser --disabled-login --disabled-password adb
USER adb
CMD ["/usr/local/bin/adb", "-a", "nodaemon", "server"]