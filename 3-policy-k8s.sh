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
# fails because of unsigned image
kubectl run test --image $DEST_REPO:unsigned
kubectl describe clusterpolicy verify-image

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
kubectl describe clusterpolicy no-vulns



