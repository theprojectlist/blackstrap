# syntax=docker/dockerfile:1


## builder
FROM debian:bullseye-slim as builder

LABEL thearchitector="Elias Gabriel <me@eliasfgabriel.com>"

# install system deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates git cmake \
        libglew-dev sudo ninja-build python3 python3-dev && \
    ln -s /usr/bin/python3 /usr/bin/python

# clone blender
ENV BLENDER_VER "2.93"
WORKDIR /blender-git
RUN git clone \
        --branch "blender-v${BLENDER_VER}-release" \
        --depth 1 \
        --jobs "$(nproc)" \
        https://git.blender.org/blender.git /blender-git/blender

# build blender dependencies
RUN ./blender/build_files/build_environment/install_deps.sh \
        --no-confirm \
        --with-all \
        --skip-ffmpeg \
        --skip-xr-openxr

# build blender
WORKDIR /blender-git/blender-build
RUN cmake ../blender -G Ninja \
        -C../blender/build_files/cmake/config/blender_headless.cmake \
        -DCMAKE_INSTALL_PREFIX=/opt/blender \
        -DWITH_INSTALL_PORTABLE=OFF \
        -DWITH_BUILDINFO=OFF \
        -DWITH_INTERNATIONAL=OFF \
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
        -DUSD_ROOT_DIR=/opt/lib/usd && \
    ninja install


## production target
FROM debian:bullseye-slim

COPY --from=builder /opt/blender/ /opt/blender/

WORKDIR /data
RUN /opt/blender/bin/blender -b -noaudio --version

ENTRYPOINT ["/opt/blender/bin/blender", "-b", "-noaudio"]
