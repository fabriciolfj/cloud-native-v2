#!/bin/sh

set -euo pipefail

echo "\nš¦ Deploying Polar UI..."

kubectl apply -f resources

echo "ā Waiting for Polar UI to be deployed..."

while [ $(kubectl get pod -l app=polar-ui | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\nā Waiting for Polar UI to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=polar-ui \
  --timeout=180s

echo "\nš¦ Polar UI deployment completed.\n"