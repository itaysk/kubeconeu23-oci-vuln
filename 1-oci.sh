#!/bin/bash

echo $SOURCE_IMAGE

# demonstrate Trivy vulnerability scan
trivy image $SOURCE_IMAGE

# scan SBOM
trivy image $SOURCE_IMAGE --format cyclonedx
trivy image $SOURCE_IMAGE --format cyclonedx >/tmp/my.cyclonedx.json
trivy sbom /tmp/my.cyclonedx.json

# push SBOM
#trivy plugin install git@github.com:aquasecurity/trivy-plugin-referrer.git
trivy image $SOURCE_IMAGE --format cyclonedx | trivy referrer put
trivy referrer list $SOURCE_IMAGE

# more artifacts
trivy image $SOURCE_IMAGE --format spdx-json | trivy referrer put
trivy image $SOURCE_IMAGE --format sarif | trivy referrer put --subject $SOURCE_IMAGE
trivy referrer list $SOURCE_IMAGE

# get a specific artifact
trivy referrer get $SOURCE_IMAGE --type application/vnd.cyclonedx+json

# Trivy discovers SBOM in registry
trivy image $SOURCE_IMAGE --sbom-sources oci