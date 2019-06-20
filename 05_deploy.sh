#!/bin/sh
# source env
source ./env.local
cp deploy2kube.template deploy2kube.yml
# replacements with sed using , syntax because we have slahes in url
sed -i '' "s,@REGISTRY@,${namespace},g" deploy2kube.yml
sed -i '' "s,@SVCNAME@,${cloudant_svc_name},g" deploy2kube.yml
sed -i '' "s,@S3_ACCESS_KEY@,${access_key_id},g" deploy2kube.yml
sed -i '' "s,@S3_SECRET_KEY@,${secret_access_key},g" deploy2kube.yml
sed -i '' "s,@S3_BUCKET@,${bucket_name},g" deploy2kube.yml
sed -i '' "s,@COS_ENDPOINT@,${host_base},g" deploy2kube.yml
sed -i '' "s,@COS_URI@,${bucket_url},g" deploy2kube.yml
sed -i '' "s,@NGINX_LOCATION@,"/",g" deploy2kube.yml
sed -i '' "s,@INGRESS_SUBDOMAIN@,${ingress_subdomain},g" deploy2kube.yml
sed -i '' "s,@INGRESS_SECRET@,${ingress_secret},g" deploy2kube.yml
sed -i '' "s,@NAMESPACE@,${cluster_namespace},g" deploy2kube.yml

# Fix Registry Pull Secret for todo Namespace
# check if Namespace exists
ns=$(kubectl get ns ${cluster_namespace})
echo $ns
if [ -z "$ns" ] ; then
    kubectl create ns ${cluster_namespace}
    echo "copy pull secret from default namepsace to ${cluster_namespace}"
    kubectl get secret default-${pull_secret_name} -o yaml --export | sed "s/default/${cluster_namespace}/g" | kubectl -n ${cluster_namespace} create -f -
    secret=${cluster_namespace}-${pull_secret_name}
    echo $secret
    patch=$(echo '{"imagePullSecrets":[{"name":"@@@"}]}' | sed  "s/@@@/${secret}/g")
    echo $patch
    echo "Patch default SA"
    kubectl patch -n ${cluster_namespace}  serviceaccount/default -p $patch
    kubectl describe serviceaccount default -n ${cluster_namespace}
    # bind secret
    bind=$(ibmcloud ks cluster-services $cluster_name --namespace $cluster_namespace | grep $cloudant_svc_name)
    echo $bind
    if [ -z "$bind" ] ; then
        echo "Cloudant servive not bound to cluster" $cloudant_svc_name
        echo "binding..."
        ibmcloud ks cluster-service-bind --cluster $cluster_name --namespace $cluster_namespace --service $cloudant_svc_name --role Manager
    else
        echo "Cloudant service already bound to cluster " $cloudant_svc_name
    fi
fi

kubectl apply -f deploy2kube.yml
