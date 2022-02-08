# syntax=docker/dockerfile:1

FROM debian:bullseye-slim

LABEL thearchitector="Elias Gabriel <me@eliasfgabriel.com>"

# install system deps
SHELL ["/bin/bash", "-c"]
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates git cmake subversion\
        file ninja-build python3-dev sudo && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python

# clone blender
ENV BLENDER_VER "2.93"
WORKDIR /blender-git
RUN git clone \
        --depth 1 \
        --branch "blender-v$BLENDER_VER-release" \
        --jobs "$(nproc)" \
        https://git.blender.org/blender.git /blender-git/blender

# build blender dependencies
# - usd 21.02 fails on ARM. bump the version to 21.08 and remove the failing diff patch
# - blosc 1.5.0 fails to compile on ARM. bump the version to 1.5.4
# - most ARM do not support SIMD, so we disable it if on those CPUs
# - replace make with ninja for speed (though they're likely similar)
RUN USE_SIMD="$([[ $(uname -m) == 'x86_64' ]] && T='avx2' || T=0; echo $T)" && \
    BLOSC_SIMD="$([[ $USE_SIMD != 'avx2' ]] && T='-O3' || T=''; echo $T)" && \
    sed -i \
       "s/USD_VERSION=\"21.02\"/USD_VERSION=\"21.08\"/g; \
        s/patch -d \$_src -p1 < \$SCRIPT_DIR\/patches\/usd.diff//g; \
        s/BLOSC_VERSION=\"1.5.0\"/BLOSC_VERSION=\"1.5.4\"/g; \
        s/KS=OFF/KS=OFF -DCMAKE_C_FLAGS='$BLOSC_SIMD'/g; \
        s/sse2/$USE_SIMD/g; \
        s/cmake \$cmake_d/cmake \$cmake_d -G Ninja/g; \
        s/make -j\$THREADS/ninja/g; s/&& make //g; \
        s/make clean//g" \
        ./blender/build_files/build_environment/install_deps.sh && \
    ./blender/build_files/build_environment/install_deps.sh \
        --source /blender-git/libsource \
        --no-confirm \
        --with-opencollada \
        --with-embree \
        --with-oidn \
        --skip-ffmpeg \
        --skip-xr-openxr

# build blender
WORKDIR /blender-git/blender-build
RUN cmake -S ../blender -G Ninja \
        -C../blender/build_files/cmake/config/blender_headless.cmake \
        -DCMAKE_INSTALL_PREFIX=/opt/blender \
        -DWITH_INSTALL_PORTABLE=OFF \
        -DWITH_BUILDINFO=OFF \
        -DWITH_INTERNATIONAL=OFF \
        -DOPENCOLORIO_ROOT_DIR=/opt/lib/ocio \
        -DOPENIMAGEIO_ROOT_DIR=/opt/lib/oiio \
        -DOSL_ROOT_DIR=/opt/lib/osl \
        -DOPENSUBDIV_ROOT_DIR=/opt/lib/osd \
        -DOPENVDB_ROOT_DIR=/opt/lib/openvdb \
        -DBLOSC_ROOT_DIR=/opt/lib/blosc \
        -DOPENCOLLADA_ROOT_DIR=/opt/lib/opencollada \
        -DEMBREE_ROOT_DIR=/opt/lib/embree \
        -DOPENIMAGEDENOISE_ROOT_DIR=/opt/lib/oidn \
        -DALEMBIC_ROOT_DIR=/opt/lib/alembic \
        -DUSD_ROOT_DIR=/opt/lib/usd && \
    ninja install

# test and entrypoint
WORKDIR /data
RUN rm -rf /blender-git && \
    /opt/blender/bin/blender -b -noaudio --version

ENTRYPOINT ["/opt/blender/bin/blender", "-b", "-noaudio"]
