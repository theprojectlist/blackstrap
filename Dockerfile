# syntax=docker/dockerfile:1


FROM debian:bullseye-slim as base

LABEL authors="Elias Gabriel <me@eliasfgabriel.com>"
MAINTAINER thearchitector

RUN apt update && \
    apt install -y \
        build-essential git subversion cmake libx11-dev libxxf86vm-dev \
        libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libglew-dev \
        sudo ninja-build python3 && \
        ln -s /usr/bin/python3 /usr/bin/python

ENV BLENDER_VER "2.93"
RUN mkdir /blender-git && \
    git clone https://git.blender.org/blender.git /blender-git/blender && \
    cd /blender-git/blender && \
    git checkout blender-v$BLENDER_VER-release

RUN cd /blender-git && \
    ./blender/build_files/build_environment/install_deps.sh \
        --with-all \
        --skip-ffmpeg \
        --skip-xr-openxr
RUN mkdir /blender-git/blender-build && \
    cd /blender-git/blender-build && \
    cmake ../blender \
        -C../blender/build_files/cmake/config/blender_headless.cmake \
        -DCMAKE_INSTALL_PREFIX=/opt/blender \
        -DWITH_INSTALL_PORTABLE=OFF \
        -DWITH_BUILDINFO=OFF \
        -DPYTHON_VERSION=3.9 \
        -DWITH_OPENCOLORIO=ON \
        -DOPENCOLORIO_ROOT_DIR=/opt/lib/ocio \
        -DWITH_OPENIMAGEIO=ON \
        -DOPENIMAGEIO_ROOT_DIR=/opt/lib/oiio \
        -DWITH_CYCLES_OSL=ON \
        -DWITH_LLVM=ON \
        -DLLVM_VERSION=11.0.1 \
        -DOSL_ROOT_DIR=/opt/lib/osl \
        -DWITH_OPENSUBDIV=ON \
        -DOPENSUBDIV_ROOT_DIR=/opt/lib/osd \
        -DWITH_OPENVDB=ON \
        -DWITH_OPENVDB_BLOSC=ON \
        -DOPENVDB_ROOT_DIR=/opt/lib/openvdb \
        -DBLOSC_ROOT_DIR=/opt/lib/blosc \
        -DWITH_NANOVDB=ON \
        -DNANOVDB_ROOT_DIR=/opt/lib/nanovdb \
        -DWITH_OPENCOLLADA=ON \
        -DOPENCOLLADA_ROOT_DIR=/opt/lib/opencollada \
        -DWITH_CYCLES_EMBREE=ON \
        -DEMBREE_ROOT_DIR=/opt/lib/embree \
        -DWITH_OPENIMAGEDENOISE=ON \
        -DOPENIMAGEDENOISE_ROOT_DIR=/opt/lib/oidn \
        -DWITH_ALEMBIC=ON \
        -DALEMBIC_ROOT_DIR=/opt/lib/alembic \
        -DWITH_USD=ON \
        -DUSD_ROOT_DIR=/opt/lib/usd
RUN cd /blender-git/blender-build && \
    ls -ahl && \
    cat Makefile && \
    ninja -G Ninja


FROM base as final

COPY --from=base /opt/blender/ /opt/blender/

WORKDIR /data
RUN /opt/blender/blender -b -noaudio --version

ENTRYPOINT ["/opt/blender/blender", "-b", "-noaudio"]
