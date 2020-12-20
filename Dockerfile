FROM debian:stable-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_ARG0="/usr/local/bin/readsb" \
    BRANCH_RTLSDR="d794155ba65796a76cd0a436f9709f4601509320"

# Note, the specific commit of rtlsdr is to address issue #3
# See: https://github.com/mikenye/docker-readsb/issues/3
# This should be revisited in future when rtlsdr 0.6.1 or newer is released

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY rootfs/ /

RUN set -x && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bison \
        bc \
        ca-certificates \
        cmake \
        curl \
        file \
        g++ \
        gcc \
        gnupg \
        jq \
        libc-dev \
        libedit-dev \
        libfl-dev \
        libncurses-dev \
        libncurses6 \
        libtecla-dev \
        libtecla1 \
        libusb-1.0-0 \
        libusb-1.0-0-dev \
        libxml2 \
        libxml2-dev \
        make \
        lighttpd \
        pkg-config \
        git \
        && \
    git config --global advice.detachedHead false && \
    echo "========== Building RTL-SDR ==========" && \
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    pushd /src/rtl-sdr && \
    #BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    #git checkout "tags/${BRANCH_RTLSDR}" && \
    git checkout "${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    pushd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    popd && popd && \
    echo "========== Building bladeRF ==========" && \
    git clone --recursive https://github.com/Nuand/bladeRF.git /src/bladeRF && \
    pushd /src/bladeRF && \
    BRANCH_BLADERF=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_BLADERF}" && \
    echo "bladeRF ${BRANCH_BLADERF}" >> /VERSIONS && \
    mkdir /src/bladeRF/host/build && \
    pushd /src/bladeRF/host/build && \
    cmake \
        -DTREAT_WARNINGS_AS_ERRORS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        ../ \
        && \
    make && \
    make install && \
    popd && popd && \
    echo "========== Downloading bladeRF FPGA Images ==========" && \
    BLADERF_RBF_PATH="/usr/share/Nuand/bladeRF" && \
    mkdir -p "$BLADERF_RBF_PATH" && \
    curl -o $BLADERF_RBF_PATH/hostedxA4.rbf https://www.nuand.com/fpga/hostedxA4-latest.rbf && \
    curl -o $BLADERF_RBF_PATH/hostedxA9.rbf https://www.nuand.com/fpga/hostedxA9-latest.rbf && \
    curl -o $BLADERF_RBF_PATH/hostedx40.rbf https://www.nuand.com/fpga/hostedx40-latest.rbf && \
    curl -o $BLADERF_RBF_PATH/hostedx115.rbf https://www.nuand.com/fpga/hostedx115-latest.rbf && \
    curl -o $BLADERF_RBF_PATH/adsbxA4.rbf https://www.nuand.com/fpga/adsbxA4.rbf && \
    curl -o $BLADERF_RBF_PATH/adsbxA9.rbf https://www.nuand.com/fpga/adsbxA9.rbf && \
    curl -o $BLADERF_RBF_PATH/adsbx40.rbf https://www.nuand.com/fpga/adsbx40.rbf && \
    curl -o $BLADERF_RBF_PATH/adsbx115.rbf https://www.nuand.com/fpga/adsbx115.rbf && \
    echo "========== Building libiio ==========" && \
    git clone https://github.com/analogdevicesinc/libiio.git /src/libiio && \
    pushd /src/libiio && \
    BRANCH_LIBIIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_LIBIIO}" && \
    echo "libiio ${BRANCH_LIBIIO}" >> /VERSIONS && \
    cmake PREFIX=/usr/local ./ && \
    make && \
    make install && \
    popd && \
    echo "========== Building libad9361-iio ==========" && \
    git clone https://github.com/analogdevicesinc/libad9361-iio.git /src/libad9361-iio && \
    pushd /src/libad9361-iio && \
    BRANCH_LIBAD9361IIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_LIBAD9361IIO}" && \
    echo "libad9361-iio ${BRANCH_LIBAD9361IIO}" >> /VERSIONS && \
    cmake ./ && \
    make && \
    make install && \
    popd && \
    echo "========== Building readsb ==========" && \
    git clone https://github.com/Mictronics/readsb.git /src/readsb && \
    pushd /src/readsb && \
    BRANCH_READSB=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_READSB}" && \
    echo "readsb ${BRANCH_READSB}" >> /VERSIONS && \
    make RTLSDR=yes BLADERF=yes PLUTOSDR=yes HAVE_BIASTEE=yes && \
    cp -v /src/readsb/readsb /usr/local/bin/readsb && \
    cp -v /src/readsb/viewadsb /usr/local/bin/viewadsb && \
    mkdir -p /usr/share/readsb/bladerf && \
    cp -v /src/readsb/bladerf/*.rbf /usr/share/readsb/bladerf/ && \
    popd && \
    echo "========== Install readsb webapp ==========" && \
    mkdir -p /usr/share/readsb/html && \
    cp -Rv /src/readsb/webapp/src/* /usr/share/readsb/html/ && \
    ln -s /etc/lighttpd/conf-available/01-setenv.conf /etc/lighttpd/conf-enabled/01-setenv.conf && \
    cp -v /src/readsb/debian/lighttpd/* /etc/lighttpd/conf-enabled/ && \
    mkdir -p /run/readsb && \
    echo "========== Deploy s6-overlay ==========" && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "========== Clean-up ==========" && \
    apt-get remove -y \
        bison \
        cmake \
        curl \
        file \
        g++ \
        gcc \
        git \
        gnupg \
        libc-dev \
        libedit-dev \
        libfl-dev \
        libncurses-dev \
        libtecla-dev \
        libusb-1.0-0-dev \
        libxml2-dev \
        make \
        pkg-config \
        && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    cat /VERSIONS && \
    readsb --version | cut -d ' ' -f2- > /CONTAINER_VERSION

# Expose ports
EXPOSE 30104/tcp 8080/tcp 30001/tcp 30002/tcp 30003/tcp 30004/tcp 30005/tcp 30105/tcp

# Set s6 init as entrypoint
ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=300s --interval=300s CMD /scripts/healthcheck.sh
