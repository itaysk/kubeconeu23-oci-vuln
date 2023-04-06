#!/bin/bash

export SOURCE_REGISTRY=ghcr.io
export SOURCE_REPO=$SOURCE_REGISTRY/toddysm/cssc-pipeline/flasksample
export SOURCE_IMAGE=$SOURCE_REPO:kubeconeu-demo-v1
echo $SOURCE_IMAGE

# Demonstrate Trivy vulnerability scan
trivy image $SOURCE_IMAGE

# Generate SBOM
trivy image $SOURCE_IMAGE --format cyclonedx
# Push SBOM to registry
trivy image $SOURCE_IMAGE --format cyclonedx | regctl artifact put --subject $SOURCE_IMAGE \
  --artifact-type application/vnd.cyclonedx+json --file-media-type application/vnd.cyclonedx+json --annotation createdby=trivy
# Another SBOM
trivy image $SOURCE_IMAGE --format spdx-json | regctl artifact put --subject $SOURCE_IMAGE \
  --artifact-type application/spdx+json --file-media-type application/spdx+json --annotation createdby=trivy
regctl artifact tree $SOURCE_IMAGE

# Demonstrate referrers API fallback tag
regctl tag list $SOURCE_IMAGE
regctl manifest get "$SOURCE_REPO":TODO

# Demonstrate process of fetching SBOM from registry
regctl artifact list $SOURCE_IMAGE --filter-artifact-type application/spdx+json --filter-annotation createdby=trivy
regctl artifact get $SOURCE_IMAGE@TODO
# Fetch SBOM from registry
regctl artifact list $SOURCE_IMAGE --filter-artifact-type application/spdx+json --filter-annotation createdby=trivy --format '{{ (index .Descriptors 0).Digest  }}' \
  | xargs -I {} regctl artifact get $SOURCE_IMAGE@{}

# Demonstrate Trivy finds SBOM in registry and uses it for vulnerability scan
trivy image $SOURCE_IMAGE --sbom-sources oci

# Generate SARIF vulnerability report and push to registry
trivy image $SOURCE_IMAGE --format sarif | regctl artifact put --subject $SOURCE_IMAGE \
  --artifact-type application/sarif+json --file-media-type application/sarif+json --annotation createdby=trivy
