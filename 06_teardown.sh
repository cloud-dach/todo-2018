#!/bin/sh
# source env
source ./env.local
ibmcloud ks cluster-service-unbind --cluster $cluster_name --namespace $cluster_namespace --service $cloudant_svc_name
ibmcloud resource service-instance-delete $cloudant_svc_name
kubectl delete -f deploy2kube.yaml -n $cluster_namespace
kubectl delete secret binding-todo-cloudant -n $cluster_namespace
kubectl delete ns $cluster_namespace
s3cmd del --force --recursive -v --host-bucket=$host_bucket --host=$host_base --access_key=$access_key_id --secret_key=$secret_access_key -v --acl-private s3://$bucket_name
