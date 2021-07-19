#!/bin/bash

echo "The following deployments are cephfs clients and will be unavailable during initial ceph upgrade:"
echo ""

client_list=$(kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName=="ceph-cephfs-external") | .metadata.namespace, .metadata.name')
client_array=( $client_list )
array_length=${#client_array[@]}
while [[ "$cnt" -lt "$array_length" ]]; do
  ns="${client_array[$cnt]}"
  cnt=$((cnt+1))
  pvc_name="${client_array[$cnt]}"
  cnt=$((cnt+1))
  for deployment in $(kubectl get deployment -n $ns -o json | jq -r '.items[].metadata.name'); do
    kubectl get deployment -n $ns $deployment -o yaml | grep -q "claimName: $pvc_name"
    if [[ "$?" -eq 0 ]]; then
      echo "  Deployment: $deployment in $ns namespace"
    fi
  done
done
echo ""