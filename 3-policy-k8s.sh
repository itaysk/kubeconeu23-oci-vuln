#! /bin/bash

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



