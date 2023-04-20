#!/bin/zsh

# This script uses the slow() function from Brandon Mitchell available at 
# https://github.com/sudo-bmitch/presentations/blob/main/oci-referrers-2023/demo-script.sh#L23
# to simulate typing the commands

opt_a=0
opt_s=25

while getopts 'ahs:' option; do
  case $option in
    a) opt_a=1;;
    h) opt_h=1;;
    s) opt_s="$OPTARG";;
  esac
done
set +e
shift `expr $OPTIND - 1`

if [ $# -gt 0 -o "$opt_h" = "1" ]; then
  echo "Usage: $0 [opts]"
  echo " -h: this help message"
  echo " -s bps: speed (default $opt_s)"
  exit 1
fi

slow() {
  echo -n "\$ $@" | pv -qL $opt_s
  if [ "$opt_a" = "0" ]; then
    read lf
  else
    echo
  fi
}

# Prepare the environment 
# Sign into Azure
az login
# NOTE: Already done in the previous demo. Setting the env vars for this script
# NOTE: Cosign and Notation must be installed and configured on the machine
export SOURCE_REGISTRY=ghcr.io
export DEST_REGISTRY=registry.twnt.co
export SOURCE_REPO=ghcr.io/toddysm/cssc-pipeline/flasksample
export DEST_REPO=registry.twnt.co/flasksample
export SOURCE_IMAGE=ghcr.io/toddysm/cssc-pipeline/flasksample:kubeconeu-demo-v1
export DEST_IMAGE=registry.twnt.co/flasksample:kubeconeu-demo-v1
# This is password for the Cosign signing key
export COSIGN_PASSWORD='P4ssW0rd1!'
# Set the Cosign experimental flag
export COSIGN_EXPERIMENTAL=1

# Copy the image in OCI format
# skopeo copy --format=oci docker://toddysm/flasksample:kubeconeu-demo-v1 docker://${SOURCE_IMAGE}

# Attach the artifacts
# trivy image -f cyclonedx $SOURCE_IMAGE > ./kubecon-eu-2023-talks/sboms/flasksample-cyclonedx.json
# trivy image -f spdx-json $SOURCE_IMAGE > ./kubecon-eu-2023-talks/sboms/flasksample-spdx.json
# trivy image -f sarif $SOURCE_IMAGE > ./kubecon-eu-2023-talks/vulnerability-reports/flasksample-20230405.sarif
# oras attach --artifact-type application/vnd.cyclonedx --annotation "createdby=trivy" $SOURCE_IMAGE ./kubecon-eu-2023-talks/sboms/flasksample-cyclonedx.json
# oras attach --artifact-type application/spdx+json --annotation "createdby=trivy" $SOURCE_IMAGE ./kubecon-eu-2023-talks/sboms/flasksample-spdx.json
# oras attach --artifact-type application/sarif+json --annotation "createdby=trivy" $SOURCE_IMAGE ./kubecon-eu-2023-talks/vulnerability-reports/flasksample-20230405.sarif

# Set the path
# export PATH=/Users/toddysm/Documents/Development/kubecon-eu-2023-talks/bin:$PATH

clear
slow

# Recap the status
slow 'regctl artifact tree $SOURCE_IMAGE'
regctl artifact tree $SOURCE_IMAGE

slow

# Set up the Cosign key and sign the image
slow 'export COSIGN_KEY=./kubecon-eu-2023-talks/sigstore/cosign.key
$ cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 $SOURCE_IMAGE'
export COSIGN_KEY=./kubecon-eu-2023-talks/sigstore/cosign.key
cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 $SOURCE_IMAGE

slow
clear

# Get ths CycloneDX SBOM and sign it
slow 'SOURCE_CYCLONE_DX=`regctl artifact tree --filter-artifact-type application/vnd.cyclonedx $SOURCE_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
$ cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_CYCLONE_DX}'
SOURCE_CYCLONE_DX=`regctl artifact tree --filter-artifact-type application/vnd.cyclonedx $SOURCE_IMAGE --format "{{json .}}" | jq -r '.referrer | .[0].reference.Digest'`
cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_CYCLONE_DX} | echo

slow
clear
echo

# Get ths SPDX SBOM and sign it
slow 'SOURCE_SPDX=`regctl artifact tree --filter-artifact-type application/spdx-json $SOURCE_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
$ cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_CYCLONE_DX}'
SOURCE_SPDX=`regctl artifact tree --filter-artifact-type application/spdx+json $SOURCE_IMAGE --format "{{json .}}" | jq -r '.referrer | .[0].reference.Digest'`
cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_SPDX} | echo

slow
clear

# Get ths SARIF and sign it
slow 'SOURCE_SARIF=`regctl artifact tree --filter-artifact-type application/sarif+json $SOURCE_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
$ cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_SARIF}'
SOURCE_SARIF=`regctl artifact tree --filter-artifact-type application/sarif+json $SOURCE_IMAGE --format "{{json .}}" | jq -r '.referrer | .[0].reference.Digest'`
cosign sign -y --key $COSIGN_KEY --registry-referrers-mode oci-1-1 ${SOURCE_REPO}@${SOURCE_SARIF} | echo

slow
clear

# Show the hierarchy in the source registry
slow 'regctl artifact tree $SOURCE_IMAGE'
regctl artifact tree $SOURCE_IMAGE

slow
clear

# Copy everything to the enterprise registry
slow 'regctl image copy --referrers --force-recursive $SOURCE_IMAGE $DEST_IMAGE'
regctl image copy --referrers --force-recursive $SOURCE_IMAGE $DEST_IMAGE

# Show again the existing destination with the copied artifacts
slow 'regctl artifact tree $DEST_IMAGE'
regctl artifact tree $DEST_IMAGE

slow
clear

# Set up Cosign verification and Notation signing and verify the image signature with Cosign
slow 'export COSIGN_KEY=./kubecon-eu-2023-talks/sigstore/cosign.pub
$ export NOTATION_KEY_NAME=tsmacrusw3kubeconeu23-azurecr-io
$ cosign verify --key $COSIGN_KEY $DEST_IMAGE'
export COSIGN_KEY=./kubecon-eu-2023-talks/sigstore/cosign.pub
export NOTATION_KEY_NAME=tsmacrusw3kubeconeu23-azurecr-io
cosign verify --key $COSIGN_KEY $DEST_IMAGE

# Resign the image with Notation
slow 'notation sign --signature-format cose --key $REMOTE_KEY_NAME $DEST_IMAGE'
notation sign --signature-format cose --key $NOTATION_KEY_NAME $DEST_IMAGE

slow
clear

# Get the digests of each artifact attached to the image
slow 'DEST_CYCLONE_DX=`regctl artifact tree --filter-artifact-type application/vnd.cyclonedx $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
$ DEST_SPDX=`regctl artifact tree --filter-artifact-type application/spdx+json $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
$ DEST_SARIF=`regctl artifact tree --filter-artifact-type application/sarif+json $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`'
DEST_CYCLONE_DX=`regctl artifact tree --filter-artifact-type application/vnd.cyclonedx $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
DEST_SPDX=`regctl artifact tree --filter-artifact-type application/spdx+json $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`
DEST_SARIF=`regctl artifact tree --filter-artifact-type application/sarif+json $DEST_IMAGE --format "{{json .}}" | jq -r ".referrer | .[0].reference.Digest"`

# Verify each of the artifacts with Cosign and resign with Notation
slow 'cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_CYCLONE_DX}'
cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_CYCLONE_DX}
slow 'notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_CYCLONE_DX}'
notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_CYCLONE_DX}

slow 'cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_SPDX}'
cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_SPDX}
slow 'notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_SPDX}'
notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_SPDX}

slow 'cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_SARIF}'
cosign verify --key $COSIGN_KEY ${DEST_REPO}@${DEST_SARIF}
slow 'notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_SARIF}'
notation sign --signature-format cose --key $NOTATION_KEY_NAME ${DEST_REPO}@${DEST_SARIF}

slow
clear

# Show again the existing destination with the copied artifacts
slow 'regctl artifact tree $DEST_IMAGE'
regctl artifact tree $DEST_IMAGE

slow