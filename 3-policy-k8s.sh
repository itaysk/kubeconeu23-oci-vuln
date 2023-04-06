#! /bin/bash

export DEST_PUBKEY='-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtkuIARvuFzS+vT6B7UJ3
dIz+/WWNQ5pAQukN3vf3TP5Ik60Rfai9LKgeoXT+znhyAFg8T5BamTtwiiWTb3BQ
upDHWbUh2VGr8k+8BDgaXSGtwCxqDsJniVUSkD8MBuJ89nsbT5miEVjfoDtNgN6E
5qXD9bsmkDcTqJZQr2KQHrSz7qceP8oG5YSI5UZ2R2KCD2Nlwy8yNwptnsko9lpD
xvpyDtyJj8QdALNhcPSBP/fez76TFfTvjet37Miah8x4IPrz2Cd6PzQCVk/0Qk3R
jTQFP8p7s86QWNoF7mSqb/1s7kN3mfbyQvpEOuqipAIiMqdalHgyqaHbIgzlZfEe
vQIDAQAB
-----END PUBLIC KEY-----'

kubectl get all

# policy - only signed images
envsubst <policy-verify.yaml.tmpl
envsubst <policy-verify.yaml.tmpl | kubectl create -f -
# succeeds because of signed image
kubectl run test --image $DEST_IMAGE
kubectl get pod -w
kubectl delete pod test

# policy - no critical vulnerabilities
envsubst <policy-vuln.yaml.tmpl
envsubst <policy-vuln.yaml.tmpl | kubectl create -f -
# fails because of critical vulnerability
kubectl run test --image $DEST_IMAGE
# try to manupulate report
trivy image $DEST_IMAGE --format sarif --severity LOW
trivy image $DEST_IMAGE --format sarif --severity LOW | regctl artifact put --subject $DEST_IMAGE \
  --artifact-type application/sarif+json --file-media-type application/sarif+json --annotation createdby=trivy
# fails because of sbom verification
kubectl run test --image $DEST_IMAGE
# use fixed image
regctl tag list $DEST_REPO | grep 'fixed'
regctl artifact tree $DEST_REPO:fixed
kubectl run test --image $DEST_REPO:fixed

kubectl describe clusterpolicy no-vulns

# policy - no GPL dependencies in SBOM



