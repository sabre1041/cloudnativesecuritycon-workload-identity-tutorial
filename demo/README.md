# Workload Identity Tutorial for Cloud Native Security Con 2024

## Initialize the Demo Cluster
Create a One Node OpenShift Cluster (4.14), size m5a.2xlarge  here [https://demo.redhat.com/catalog](https://demo.redhat.com/catalog)


## Obtain the deployment scripts for the demo

```console
git clone -b dev https://github.com/sabre1041/cloudnativesecuritycon-workload-identity-tutorial.git
cd cloudnativesecuritycon-workload-identity-tutorial/demo/
```

## Deploy the Demo Application

Create a new namespace called demo

```console
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: demo
EOF
```

Deploy MySql:

This command deploys, initializes MySql service and then populates it with the sample entries. 

```console
kubectl apply -f config/db-node.yaml -n demo
```
