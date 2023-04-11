#! /bin/bash

kubectl get all

# policy - only signed images
kubectl create -f policy-imagesign.yaml
# succeeds because of signed image
kubectl run test --image $DEST_IMAGE
kubectl get pod -w
kubectl delete pod test

# policy - no GPL dependencies in SBOM
kubectl create -f policy-licenses.yaml
# failes due to GPL dependency
kubectl run test --image $DEST_IMAGE
kubectl get pod -w

# policy - no critical vulnerabilities
kubectl create -f policy-vulnerabilities.yaml
# fails because of critical vulnerability
kubectl run test --image $DEST_IMAGE
# succeeds when using fixed image
kubectl run test --image $DEST_REPO:fixed
kubectl delete pod test




