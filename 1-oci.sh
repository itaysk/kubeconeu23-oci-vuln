#!/bin/bash

echo $SOURCE_IMAGE

# regular image scan
trivy image $SOURCE_IMAGE

# image scan using SBOM
trivy image $SOURCE_IMAGE --format cyclonedx
trivy image $SOURCE_IMAGE --format cyclonedx >/tmp/my.cyclonedx.json
trivy sbom /tmp/my.cyclonedx.json

# store SBOM in registry
trivy image $SOURCE_IMAGE --format cyclonedx | regctl artifact put --subject $SOURCE_IMAGE \
  --artifact-type application/vnd.cyclonedx+json --file-media-type application/vnd.cyclonedx+json \
  --annotation "created-by=trivy" --annotation created=$(date -Iseconds)
trivy plugin install git@github.com:aquasecurity/trivy-plugin-referrer.git
trivy image $SOURCE_IMAGE --format cyclonedx | trivy referrer put

trivy image $SOURCE_IMAGE --format spdx-json | trivy referrer put
trivy image $SOURCE_IMAGE --format sarif | trivy referrer put

# list referrering artifacts
regctl artifact list $SOURCE_IMAGE
trivy referrer list $SOURCE_IMAGE --format table

# get contents of specific referring artifact
regctl artifact list $SOURCE_IMAGE --filter-artifact-type application/vnd.cyclonedx+json --filter-annotation created-by=trivy
regctl artifact get $SOURCE_IMAGE@sha256:
trivy referrer get $SOURCE_IMAGE --type cyclonedx

# image scan using SBOM from registry
trivy image $SOURCE_IMAGE --sbom-sources oci