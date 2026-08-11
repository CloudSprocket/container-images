# Contributing

## Development requirements

- Docker Engine or Docker Desktop
- Docker Buildx and Compose
- Bash (for smoke tests and static checks)
- Optional local ShellCheck, Hadolint and yamllint

## Before opening a pull request

Run static validation:

```bash
make static
# or
bash scripts/static-checks.sh
```

Build and smoke-test every image you touch:

```bash
make test-sec-forge
make test-mesh-router
make test-data-streams-producer
make test-data-streams-consumer
```

Or build without smoke tests:

```bash
make build-sec-forge
```

Run the image-local Compose demos where present:

```bash
docker compose -f images/mesh-router/examples/compose.yml up --build
docker compose -f examples/data-streams/compose.yml up --build
```

Do not weaken a documented contract to make a failing image pass. Explain
intentional behaviour changes in the pull request.

## Build policy

- Keep each image Dockerfile focused on a single purpose.
- Pin tool and library versions after verifying them against an upstream source.
- Prefer release artefacts with checksum verification over `curl | sh`.
- Do not add fixed passwords, keys, tokens or registry credentials.
- Prefer a non-root default user where the image purpose allows it.
- Document every runtime environment variable in the image README.
- Pin GitHub Actions to full commit SHAs with a version comment.

Operating-system package versions from a distribution repository are
intentionally not pinned individually unless a specific package is the reason
the image exists. Tool versions that define the image (scanners, clients,
language libraries) must be pinned.

## Versioning

Images version independently. There is no root `VERSION` file.

- Each image records its current release in `images/<name>/VERSION`.
- Git release tags are `<name>-v<major.minor.patch>` (for example
  `sec-forge-v0.1.0`).
- Docker Hub receives `latest` and the bare semver tag, sharing one multi-arch
  digest. See [RELEASE.md](RELEASE.md).

## Adding a new image

Follow this checklist so image number five (and beyond) is a small, obvious
operation:

1. Create `images/<name>/` with at least:
   - `Dockerfile`
   - `README.md` (purpose, platforms, pins, configuration, build)
   - `VERSION` starting at `0.1.0`
2. Add a build target and a matching `release-<name>` target in
   `docker-bake.hcl`, including OCI labels and the Hub repository name
   `cloudsprocket/<name>`.
3. Append `<name>` to the `IMAGES` list in the `Makefile` (pattern rules cover
   `build-<name>` and `test-<name>`).
4. Add a smoke-test branch for `<name>` in `scripts/smoke-test.sh` that proves
   the container actually works, not merely that it builds.
5. Extend `scripts/verify-manifests.sh` and
   `scripts/update-dockerhub-metadata.ps1` with the new Hub repository.
6. Wire path filters and the image matrix into `.github/workflows/ci.yml` so a
   change under `images/<name>/` rebuilds only that image (shared root files
   still rebuild everything).
7. Add the tag pattern `<name>-v*.*.*` and any image-name parsing cases in
   `.github/workflows/release.yml`.
8. Document the image in the root [README.md](README.md) and
   [SUPPORT.md](SUPPORT.md), and note it under Unreleased in
   [CHANGELOG.md](CHANGELOG.md).
9. Create the empty public Docker Hub repository `cloudsprocket/<name>` before
   the first release.
10. Open the pull request. After merge, cut the first release tag
    `<name>-v0.1.0` and refresh Hub metadata with
    `.\scripts\update-dockerhub-metadata.ps1 -Apply`.

## Style

- British English throughout.
- Do not use em dashes.
