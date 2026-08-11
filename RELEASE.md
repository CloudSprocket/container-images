# Release process

## Repository configuration

Create a protected GitHub environment named `dockerhub` with required reviewer
approval. Add these environment secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`, using a scoped access token rather than an account password

The following public Docker Hub repositories must exist before a release:

- `cloudsprocket/sec-forge`
- `cloudsprocket/mesh-router`
- `cloudsprocket/data-streams-producer`
- `cloudsprocket/data-streams-consumer`

## Per-image versioning

Images do not share a monorepo version. Each image keeps its own
`images/<name>/VERSION` file (`major.minor.patch`).

Git release tags use this exact format:

```text
<image>-v<major.minor.patch>
```

Examples:

```text
sec-forge-v0.1.0
mesh-router-v0.1.0
data-streams-producer-v0.1.0
data-streams-consumer-v0.1.0
```

## Release requirements

1. Update `images/<name>/VERSION` to the intended `major.minor.patch` value.
2. Record the change under that image in [CHANGELOG.md](CHANGELOG.md).
3. Require green CI for the exact commit (path-filtered builds for that image
   are enough when only that image changed).
4. Review vulnerability results and resolve every fixable high or critical
   finding that the image's purpose requires. Any exception must be
   time-limited and documented in release notes.
5. Push a signed tag matching `<image>-v<version>`, or run the Release workflow
   manually with the image name and version. The tag version must match
   `images/<name>/VERSION`.

## What the workflow publishes

For the tagged image only, the workflow creates:

- a moving `latest` tag;
- an immutable semantic-version tag (`<version>`, without the image prefix);
- amd64 and arm64 manifests that share one digest across `latest` and the
  version tag;
- BuildKit SBOM and maximum provenance attestations.

The workflow then verifies platform manifests, confirms `latest` and the
immutable version share a digest, and creates a GitHub release for that tag.

## After the workflow succeeds

Refresh the Docker Hub short descriptions and overviews so they reference the
new immutable tag:

```powershell
.\scripts\update-dockerhub-metadata.ps1 -Apply
```

The script reads each image's `VERSION` file, authenticates with the Docker
Hub credentials held by Docker Desktop and updates all four repositories. Run
it without `-Apply` to preview the current state first.

Every Hub overview must include a description, a source-code link, a
contributing-guidelines link and the organisation website
(https://cloudsprocket.org). Those four items are required for Docker-Sponsored
Open Source compliance in this namespace.

## Rollback

An affected repository's `latest` tag can be restored to a previously verified
immutable manifest. Never overwrite or delete a versioned release tag. Record
the reason and restored digest in a GitHub release note and security advisory
when applicable.
