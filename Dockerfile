# syntax=docker/dockerfile:1


# builder stage
FROM debian:bullseye-slim as builder

LABEL thearchitector="Elias Gabriel <me@eliasfgabriel.com>"

## install system deps
SHELL ["/bin/bash", "-c"]
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates git cmake file \
        ninja-build python3 python3-dev && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python

## clone blender
ENV BLENDER_VER "2.93"
WORKDIR /blender-git
RUN git clone \
        --depth 1 \
        --branch "blender-v$BLENDER_VER-release" \
        --jobs "$(nproc)" \
        https://git.blender.org/blender.git /blender-git/blender

## build blender dependencies
## - sudo should not be available, so alias it to "eval"
## - most ARM do not support SIMD, so we disable it if on those CPUs
## - replace make with ninja for speed (though they're likely similar)
RUN USE_SIMD="$([[ $(uname -m) == 'x86_64' ]] && T='sse4.1,sse4.2,avx2' || T=0; echo $T)" && \
    sed -i "s/\"sudo\"/\"eval\"/g; \
        s/sse2/$USE_SIMD/g; \
        s/cmake \$cmake_d/cmake \$cmake_d -G Ninja/g; \
        s/make -j\$THREADS/ninja/g; s/&& make //g; \
        s/make clean/ninja -t clean -g/g" \
        ./blender/build_files/build_environment/install_deps.sh && \
    ./blender/build_files/build_environment/install_deps.sh \
        --no-confirm \
        --with-opencollada \
        --with-embree \
        --with-oidn \
        --skip-ffmpeg \
        --skip-xr-openxr

## build blender
WORKDIR /blender-git/blender-build
RUN cmake ../blender -G Ninja \
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


# production stage
FROM debian:bullseye-slim

## copy built files from builder
COPY --from=builder /opt/ /opt/

## test and entrypoint
WORKDIR /data
RUN /opt/blender/bin/blender -b -noaudio --version

ENTRYPOINT ["/opt/blender/bin/blender", "-b", "-noaudio"]
