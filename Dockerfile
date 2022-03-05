# syntax=docker/dockerfile:1

FROM debian:bullseye-slim as builder

LABEL thearchitector="Elias Gabriel <me@eliasfgabriel.com>"

# install system deps
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends eatmydata
SHELL [ "/usr/bin/eatmydata", "/bin/bash", "-c"]
RUN apt-get install -y --no-install-recommends ca-certificates \
        git cmake file sudo python-is-python3 python3-dev ninja-build

# clone blender
ENV BLENDER_VER "2.93"
WORKDIR /blender-git
RUN git clone \
        --depth 1 \
        --branch "blender-v$BLENDER_VER-release" \
        --jobs "$(nproc)" \
        https://git.blender.org/blender.git && \
    cd ./blender && \
    git remote set-branches --add origin master && \
    git fetch \
        --depth 1 \
        --jobs "$(nproc)" \
        --progress \
        origin master:master && \
    git checkout master

# build blender dependencies
ARG OIDN_VERSION="1.3.0" OIIO_VERSION="2.1.15.0" BLOSC_VERSION="1.5.4"
WORKDIR /blender-git/blender
RUN BLOSC_SIMD="$([[ $(uname -m) == 'x86_64' ]] && T='-O3' || T=''; echo $T)" && \
    sed -i \
       "s/apt-get install -y/apt-get install -y --no-install-recommends/g; \
        s/OIDN_VERSION=/OIDN_VERSION=\"$OIDN_VERSION\"#/g; \
        s/BLOSC_VERSION=\"1.5.0\"/BLOSC_VERSION=\"$BLOSC_VERSION\"/g; \
        s/KS=OFF/KS=OFF -DCMAKE_C_FLAGS='$BLOSC_SIMD'/g; \
        s/APPS=OFF/APPS=OFF -DOCIO_USE_HEADLESS=ON -DOCIO_BUILD_TESTS=OFF/g; \
        s/TXT2MAN=/TXT2MAN= -DBUILD_DOCS=OFF -DINSTALL_DOCS=OFF/g; \
        s/NO_OPENCL=1/NO_OPENCL=1 -DNO_TESTS=1 -DNO_GLTESTS=1/g; \
        s/OLD=OFF/OLD=OFF -DUSE_TESTS=OFF/g; \
        s/PXR_BUILD_TESTS=OFF/PXR_BUILD_TESTS=OFF -DPXR_BUILD_EXAMPLES=OFF -DPXR_BUILD_TUTORIALS=OFF/g; \
        s/cmake \$cmake_d/cmake \$cmake_d -G Ninja/g; \
        s/make -j\$THREADS/ninja/g; s/&& make //g; \
        s/make clean//g" \
        ./build_files/build_environment/install_deps.sh && \
    ./build_files/build_environment/install_deps.sh \
        --no-confirm \
        --skip-python \
        --ver-oiio "$OIIO_VERSION" \
        --with-opencollada \
        --with-embree \
        --with-oidn && \
    git checkout "blender-v$BLENDER_VER-release"

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
