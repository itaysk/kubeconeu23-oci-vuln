#!/bin/bash

export SOURCE_REGISTRY=ghcr.io
export SOURCE_REPO=$SOURCE_REGISTRY/toddysm/cssc-pipeline/flasksample
export SOURCE_IMAGE=$SOURCE_REPO:kubeconeu-demo-v1
echo $SOURCE_IMAGE

# demonstrate Trivy vulnerability scan
trivy image $SOURCE_IMAGE

# generate SBOM
trivy image $SOURCE_IMAGE --format cyclonedx
# Push SBOM to registry
#trivy plugin install git@github.com:aquasecurity/trivy-plugin-referrer.git
trivy image $SOURCE_IMAGE --format cyclonedx | trivy referrer put
# another SBOM
trivy image $SOURCE_IMAGE --format spdx-json | trivy referrer put
regctl artifact tree $SOURCE_IMAGE

# demonstrate referrers API fallback tag
regctl tag list $SOURCE_IMAGE
regctl manifest get "$SOURCE_REPO":TODO

# demonstrate process of fetching SBOM from registry
regctl artifact list $SOURCE_IMAGE --filter-artifact-type application/cyclonedx+json #--filter-annotation createdby=trivy
regctl artifact get $SOURCE_IMAGE@TODO
# fetch SBOM from registry
regctl artifact list $SOURCE_IMAGE --filter-artifact-type application/cyclonedx+json --format '{{ (index .Descriptors 0).Digest  }}' \
  | xargs -I {} regctl artifact get $SOURCE_IMAGE@{}

# demonstrate Trivy finds SBOM in registry and uses it for vulnerability scan
trivy image $SOURCE_IMAGE --sbom-sources oci

# generate SARIF vulnerability report and push to registry
trivy image $SOURCE_IMAGE --format sarif | regctl artifact put --subject $SOURCE_IMAGE \
  --artifact-type application/sarif+json --file-media-type application/sarif+json #--annotation createdby=trivy
