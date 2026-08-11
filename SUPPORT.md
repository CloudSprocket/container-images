# Support policy

## Supported images

| Image | Docker Hub repository | Architectures | Notes |
| --- | --- | --- | --- |
| sec-forge | [`cloudsprocket/sec-forge`](https://hub.docker.com/r/cloudsprocket/sec-forge) | amd64, arm64 | Ubuntu 24.04 base; pinned scanner tools |
| mesh-router | [`cloudsprocket/mesh-router`](https://hub.docker.com/r/cloudsprocket/mesh-router) | amd64, arm64 | HAProxy 3.4 LTS base |
| data-streams-producer | [`cloudsprocket/data-streams-producer`](https://hub.docker.com/r/cloudsprocket/data-streams-producer) | amd64, arm64 | Current Python slim base |
| data-streams-consumer | [`cloudsprocket/data-streams-consumer`](https://hub.docker.com/r/cloudsprocket/data-streams-consumer) | amd64, arm64 | Current Python slim base |

## What support means

While an image is supported, the project intends to:

- rebuild from reviewed base tags;
- keep tool and library pins current after verification;
- publish security-driven or planned versioned releases for that image;
- document configuration and examples in each image README.

Support applies to the documented behaviour of each image. It does not include
long-running production service SLAs, persistent data guarantees or arbitrary
third-party plugins.

## Independent version lines

Each image versions on its own schedule. There is no monorepo-wide version.
Release tags use the form `<image>-v<major.minor.patch>` (for example
`sec-forge-v0.1.0`). See [RELEASE.md](RELEASE.md).

## Deprecation

An image or base line receives a deprecation notice before removal whenever
upstream timelines permit. Its moving channel stops after the final supported
release; immutable version tags remain available with an unsupported notice.
