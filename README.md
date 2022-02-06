# blackstrap

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/theprojectlist/blackstrap/Build%20and%20Push?style=flat-square)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/thearchitector/blackstrap?label=size&style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/thearchitector/blackstrap?label=pulls&style=flat-square)

Docker-based distributed Blender render farm.

## Developing

For the most part, all you need to test blackstrap is Docker. If you want to try building for ARM, though, you need to install
the proper architecture emulator:

```sh
$ docker run --privileged --rm tonistiigi/binfmt --install arm64
```

Then, you can build the for the ARM platform by adding `linux/arm64` to the `--platform` list supplied to Buildx. *Because Docker must emulate a different CPU architecture, there is a very large performance hit. Building for ARM on x86-64 takes **a lot** longer.*

```sh
$ docker buildx build --platform linux/amd64,linux/arm64 .
```