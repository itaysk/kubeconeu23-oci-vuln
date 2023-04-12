#! /bin/bash


kind create cluster
sleep 10
kubectl create secret docker-registry regcred --docker-server="$DEST_REGISTRY" --docker-username="$DEST_REGISTRY_USER" --docker-password="$DEST_REGISTRY_PASS"
kubectl patch serviceaccount default --patch '{"imagePullSecrets": [{"name": "regcred"}]}'
kubectl create -f https://gist.githubusercontent.com/Vishal-Chdhry/73ffec4b0ac8a0ab2c267c09a39f790d/raw/383a746a21b279af2ae7cbd4bb8389c233fe9a14/notation-attestation-install.yaml
kubectl set image deploy/kyverno-admission-controller -n kyverno kyverno="ghcr.io/vishal-chdhry/kyverno-notary-attestations:demov1.1"
kubectl create secret docker-registry -n kyverno regcred --docker-server="$DEST_REGISTRY" --docker-username="$DEST_REGISTRY_USER" --docker-password="$DEST_REGISTRY_PASS"
kubectl patch deployment kyverno-background-controller -n kyverno --type json --patch '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--imagePullSecrets=regcred" }]'
kubectl patch deployment kyverno-admission-controller -n kyverno --type json --patch '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--imagePullSecrets=regcred" }]'
kubectl create configmap keys -n kyverno --from-literal=notary=$DEST_PUBKEY
sleep 5
kubectl get po -n kyverno