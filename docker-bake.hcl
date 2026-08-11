variable "SEC_FORGE_IMAGE" {
  default = "docker.io/cloudsprocket/sec-forge"
}

variable "MESH_ROUTER_IMAGE" {
  default = "docker.io/cloudsprocket/mesh-router"
}

variable "DATA_STREAMS_PRODUCER_IMAGE" {
  default = "docker.io/cloudsprocket/data-streams-producer"
}

variable "DATA_STREAMS_CONSUMER_IMAGE" {
  default = "docker.io/cloudsprocket/data-streams-consumer"
}

variable "VERSION" {
  default = "dev"
}

variable "REVISION" {
  default = "local"
}

variable "CREATED" {
  default = "1970-01-01T00:00:00Z"
}

variable "SOURCE_URL" {
  default = "https://github.com/CloudSprocket/container-images"
}

group "default" {
  targets = ["sec-forge", "mesh-router", "data-streams-producer", "data-streams-consumer"]
}

group "all" {
  targets = ["sec-forge", "mesh-router", "data-streams-producer", "data-streams-consumer"]
}

group "release" {
  targets = [
    "release-sec-forge",
    "release-mesh-router",
    "release-data-streams-producer",
    "release-data-streams-consumer",
  ]
}

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.created" = CREATED
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.revision" = REVISION
    "org.opencontainers.image.source" = SOURCE_URL
    "org.opencontainers.image.url" = SOURCE_URL
    "org.opencontainers.image.version" = VERSION
  }
}

target "sec-forge" {
  inherits = ["_common"]
  context = "images/sec-forge"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket sec-forge"
    "org.opencontainers.image.description" = "CI security scanning toolbox with pinned Trivy, Grype, Semgrep and Checkov"
  }
  tags = ["${SEC_FORGE_IMAGE}:dev"]
}

target "mesh-router" {
  inherits = ["_common"]
  context = "images/mesh-router"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket mesh-router"
    "org.opencontainers.image.description" = "Configurable HAProxy 3.4 LTS front end with rate limiting and stats"
  }
  tags = ["${MESH_ROUTER_IMAGE}:dev"]
}

target "data-streams-producer" {
  inherits = ["_common"]
  context = "images/data-streams-producer"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket data-streams-producer"
    "org.opencontainers.image.description" = "Kafka/Redpanda load generator that produces synthetic events"
  }
  tags = ["${DATA_STREAMS_PRODUCER_IMAGE}:dev"]
}

target "data-streams-consumer" {
  inherits = ["_common"]
  context = "images/data-streams-consumer"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket data-streams-consumer"
    "org.opencontainers.image.description" = "Slow Kafka/Redpanda consumer for building and observing consumer lag"
  }
  tags = ["${DATA_STREAMS_CONSUMER_IMAGE}:dev"]
}

target "release-sec-forge" {
  inherits = ["sec-forge"]
  tags = [
    "${SEC_FORGE_IMAGE}:latest",
    "${SEC_FORGE_IMAGE}:${VERSION}",
  ]
}

target "release-mesh-router" {
  inherits = ["mesh-router"]
  tags = [
    "${MESH_ROUTER_IMAGE}:latest",
    "${MESH_ROUTER_IMAGE}:${VERSION}",
  ]
}

target "release-data-streams-producer" {
  inherits = ["data-streams-producer"]
  tags = [
    "${DATA_STREAMS_PRODUCER_IMAGE}:latest",
    "${DATA_STREAMS_PRODUCER_IMAGE}:${VERSION}",
  ]
}

target "release-data-streams-consumer" {
  inherits = ["data-streams-consumer"]
  tags = [
    "${DATA_STREAMS_CONSUMER_IMAGE}:latest",
    "${DATA_STREAMS_CONSUMER_IMAGE}:${VERSION}",
  ]
}
