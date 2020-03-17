FROM debian:stable-slim AS builder_rtlsdr

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_ARG0=/usr/local/bin/readsb

RUN set -x && \
    apt-get update -y && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        cmake \
        gcc \
        libc-dev \
        libusb-1.0-0 \
        libusb-1.0-0-dev \
        g++ \
        libtecla1 \
        libtecla-dev \
        libedit-dev \
        libxml2 \
        libxml2-dev \
        libfl-dev \
        bison \
        pkg-config \
        libncurses6 \
        libncurses-dev \
        npm \
        nodejs \
        node-typescript \
        nginx-light \
        gnupg \
        curl && \
    git config --global advice.detachedHead false && \
    echo "========== Building RTL-SDR ==========" && \
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    cd /src/rtl-sdr && \
    export BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    git checkout tags/${BRANCH_RTLSDR} && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    cd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    echo "========== Building bladeRF ==========" && \
    git clone --recursive https://github.com/Nuand/bladeRF.git /src/bladeRF && \
    cd /src/bladeRF && \
    export BRANCH_BLADERF=$(git tag --sort="-creatordate" | head -1) && \
    git checkout ${BRANCH_BLADERF} && \
    echo "bladeRF ${BRANCH_BLADERF}" >> /VERSIONS && \
    mkdir /src/bladeRF/host/build && \
    cd /src/bladeRF/host/build && \
    cmake -DTREAT_WARNINGS_AS_ERRORS=OFF ../ && \
    make && \
    make install && \
    echo "========== Building libiio ==========" && \
    git clone https://github.com/analogdevicesinc/libiio.git /src/libiio && \
    cd /src/libiio && \
    export BRANCH_LIBIIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout ${BRANCH_LIBIIO} && \
    echo "libiio ${BRANCH_LIBIIO}" >> /VERSIONS && \
    cmake PREFIX=/usr/local ./ && \
    make -j && \
    make -j install && \
    echo "========== Building libad9361-iio ==========" && \
    git clone https://github.com/analogdevicesinc/libad9361-iio.git /src/libad9361-iio && \
    cd /src/libad9361-iio && \
    export BRANCH_LIBAD9361IIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout ${BRANCH_LIBAD9361IIO} && \
    echo "libad9361-iio ${BRANCH_LIBAD9361IIO}" >> /VERSIONS && \
    cmake ./ && \
    make -j && \
    make -j install && \
    echo "========== Building readsb ==========" && \
    git clone https://github.com/Mictronics/readsb.git /src/readsb && \
    cd /src/readsb && \
    export BRANCH_READSB=$(git tag --sort="-creatordate" | head -1) && \
    git checkout ${BRANCH_READSB} && \
    echo "readsb ${BRANCH_READSB}" >> /VERSIONS && \
    make -j RTLSDR=yes BLADERF=yes PLUTOSDR=yes HAVE_BIASTEE=yes && \
    cp -v /src/readsb/readsb /usr/local/bin/readsb && \
    cp -v /src/readsb/viewadsb /usr/local/bin/viewadsb && \
    echo "========== Final Config ==========" && \
    rm -v /etc/nginx/sites-enabled/default && \
    ln -vs /etc/nginx/sites-available/readsb /etc/nginx/sites-enabled/readsb && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "========== Clean-up ==========" && \
    apt-get remove -y \
        git \
        make \
        cmake \
        gcc \
        libc-dev \
        libusb-1.0-0-dev \
        g++ \
        libtecla-dev \
        libedit-dev \
        libxml2-dev \
        libfl-dev \
        bison \
        pkg-config \
        libncurses-dev \
        npm \
        nodejs \
        node-typescript \
        gnupg \
        curl && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /var/cache/apk/* && \
    cat /VERSIONS

# Copy config files
COPY etc/ /etc/

# Expose ports
EXPOSE 30104/tcp 80/tcp 30001/tcp 30002/tcp 30003/tcp 30004/tcp 30005/tcp

# Set s6 init as entrypoint
ENTRYPOINT [ "/init" ]
