# Release process

## Repository configuration

Create a GitHub environment named `dockerhub` holding these secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`, using a scoped access token rather than an account password

**Publishing is automated. There is no manual approval step.** Pushing a
release tag publishes to Docker Hub without further human action, so the
automated gates in the next section are what stands between a bad commit and a
public image. Treat them as the release authority and do not weaken them
without a replacement.

The following public Docker Hub repositories must exist before a release:

- `cloudsprocket/sec-forge`
- `cloudsprocket/mesh-router`
- `cloudsprocket/data-streams-producer`
- `cloudsprocket/data-streams-consumer`

## Automated gates

Five checks run per release, in this order. Any failure stops the release.

**Before anything is pushed**

1. **Version agreement.** The release job refuses to run unless the tag version
   matches `images/<name>/VERSION` exactly.
2. **Build and runtime smoke test** on both amd64 and arm64. Not a build-only
   check: sec-forge asserts all four scanners resolve under both `bash -c` and
   `bash -lc`, mesh-router renders a config from `BACKEND_SERVERS` and serves
   its stats endpoint against a real backend, and the data-streams pair connect
   to a live Redpanda broker.
3. **Vulnerability scan**, failing on any CRITICAL finding that has a fix
   available. Unfixed CVEs are deliberately excluded: nothing in this repo can
   act on them and they would block every release indefinitely, whereas a
   fixable critical means a rebuild or a version bump is genuinely outstanding.
   Raise the bar to HIGH once the estate is quiet enough to sustain it.

**After the push**

4. **Manifest verification.** Both platforms present, and `latest` and the
   immutable version tag resolving to one shared digest.
5. **Published-artefact smoke test.** The pushed image is pulled back from
   Docker Hub and put through the same runtime smoke test. Gates 2 and 3 prove
   a locally built image, which is not the same bytes as the published one;
   this proves what users actually receive.

A failure at gate 4 or 5 means a bad image is already public. Follow the
rollback section below rather than deleting the version tag.

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
4. Push a tag matching `<image>-v<version>`, or run the Release workflow
   manually with the image name and version. The tag version must match
   `images/<name>/VERSION`.

Fixable critical vulnerabilities are enforced by gate 3 rather than by review,
so there is no manual sign-off to perform. Any deliberate exception has to be a
change to the gate, made in a pull request with its reasoning, not a one-off
override at release time.

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
