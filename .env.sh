#!/bin/bash

export SOURCE_REGISTRY=ghcr.io
export SOURCE_REPO=$SOURCE_REGISTRY/toddysm/cssc-pipeline/flasksample
export SOURCE_IMAGE=$SOURCE_REPO:kubeconeu-demo-v1

export DEST_REGISTRY=registry.twnt.co
export DEST_REPO=$DEST_REGISTRY/flasksample
export DEST_IMAGE=$DEST_REPO:kubeconeu-demo-v1