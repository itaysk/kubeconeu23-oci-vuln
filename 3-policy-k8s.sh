#! /bin/bash

trivy referrer tree $DEST_IMAGE

# policy - only signed images
view policy-imagesign.yaml
kubectl create -f policy-imagesign.yaml
# succeeds because of signed image
kubectl run test --image $DEST_IMAGE
kubectl get pod -w
kubectl delete pod test

# policy - no GPL dependencies in SBOM
view policy-licenses.yaml
kubectl create -f policy-licenses.yaml
# failes due to GPL dependency
kubectl run test --image $DEST_IMAGE
kubectl get pod -w
kubectl delete -f policy-licenses.yaml


# policy - no critical vulnerabilities
view policy-vulnerabilities.yaml
kubectl create -f policy-vulnerabilities.yaml
# fails because of critical vulnerability
kubectl run test --image $DEST_IMAGE
# succeeds when using fixed image
kubectl run test --image $DEST_IMAGE_FIXED
kubectl delete pod test




