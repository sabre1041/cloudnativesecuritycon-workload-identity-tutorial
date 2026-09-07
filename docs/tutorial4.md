# Tutorial 4 - Deploying SPIRE

SPIRE represents the foundational component for providing identities to workloads and is at the heart for Kaya's proposed future state architecture to support Bob's application. She begins to assemble the resources to support her design in the `$TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure` directory which will be used throughout the upcoming sections.

## Deploying SPIRE 

SPIRE can either be deployed using the Helm charts from the SPIFFE community or from Red Hat's Zero Trust Workload Identity Manager (ZTWIM)

### SPIFFE Project Helm Charts

Similar to many Kubernetes components, there are several methods for which SPIRE can be installed. The most straightforward and scale method for deploying SPIRE is to use Helm and there are a set of [Helm charts](https://github.com/spiffe/helm-charts-hardened) that are available for deploying SPIRE.

Clone the Helm charts locally to obtain the content needed to deploy SPIRE

```shell
cd $TUTORIAL_ROOT
git clone https://github.com/spiffe/helm-charts-hardened.git
```

With the Helm charts installed locally, deploy the Kubernetes Custom Resource Definitions

```shell
helm upgrade --install --create-namespace -n spire-mgmt spire-crds $TUTORIAL_ROOT/helm-charts-hardened/charts/spire-crds
```

A custom set of Helm values is available in a file located at `$TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/demo/secure/spire-helm-values.yaml`. Feel free to inspect the contents to observe some of the configurations that are being applied.

Deploy the `spire` Helm chart with the custom Values file using the following command:

```shell
helm upgrade --install --create-namespace -n spire-mgmt spire $TUTORIAL_ROOT/helm-charts-hardened/charts/spire -f $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/spire/spire-helm-values.yaml --set global.spire.namespaces.create=true --set global.spire.trustDomain=$APP_DOMAIN --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values.yaml --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values-ingress.yaml --render-subchart-notes --dependency-update --debug
```

#### Validating the SPIRE Deployment

With the Helm chart installed to the cluster, validate that the expected set of resources were configured appropriately.

First, check that the desired pods are running in the `spire-server` namespace

```shell
kubectl -n spire-server get pods
```

A successful result should return 3 running pods with all containers running and _READY_ similar to the following:

```
NAME                                                    READY   STATUS    RESTARTS   AGE
spire-server-0                                          3/3     Running   0          9m17s
spire-spiffe-oidc-discovery-provider-7788f57c55-7zt7r   3/3     Running   0          9m17s
spire-tornjak-frontend-6bb4dc6d7c-b7kn7                 1/1     Running   0          9m17s
```

In order to provide identity to all workloads, SPIRE deploys several DaemonSet's to the `spire-system` namespace. Confirm both the `spire-agent` and `spire-spiffe-csi-driver` DaemonSet's are available and running on all nodes:

```shell
kubectl get daemonset -n spire-system
```

Confirm the desired number of desired pods matches the current, ready, up-to-date and available columns.

```
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
spire-agent               3         3         3       3            3           <none>          21m
spire-spiffe-csi-driver   3         3         3       3            3           <none>          21m
```

One of the components that are exposed outside the cluster is an OIDC provider endpoint. Set a variable `OIDC_URL` with the value of the OIDC discovery provider

```shell
export OIDC_URL=https://$(kubectl get ingress -n spire-server  spire-spiffe-oidc-discovery-provider -o jsonpath='{ .spec.rules[*].host }')
```

Confirm the [JWKS](https://tools.ietf.org/html/rfc7517) endpoint that is used to verify the signatures that are included within JWT's is available:

```shell
curl $OIDC_URL/keys
```

The final component of the SPIFFE deployment that should be validated is that Tornjak is running and available. Tornjak is a project that enables the management of SPIFFE identities managed by SPIRE.

Obtain the URL of the Tornjak endpoint:

```shell
echo  https://$(kubectl get ingress -n spire-server  spire-tornjak-frontend -o jsonpath='{ .spec.rules[*].host }') 
```

Launch a browser and navigate to the URL obtained by the output from the previous command to access Tornjak. The landing page provides a list of the nodes in the Kubernetes cluster. By clicking on the _Entries_ button on the navigation bar lists the workloads that have identities that have been issued by SPIRE. These identities will be key in Kaya's longterm architecture which will enable accessing protected resources stored within Vault which will be deployed and configured in the next tutorial exercise.

### Zero Trust Workload Identity Manager (ZTWIM)

SPIFFE can be made available through Red Hat's Zero Trust Workload Identity Manager (ZTWIM). As a layered operator, the ZTWIM operator must first be installed followed by a series of operands. The installation is streamlined with tooling provided in the [gitops-catalog](https://github.com/redhat-cop/gitops-catalog) from the Red Hat Community of Practice.

Clone the _gitops-catalog_ locally

```shell
cd $TUTORIAL_ROOT
git clone https://github.com/redhat-cop/gitops-catalog.git
```

First, install the ZTWIM operator

```shell
kubectl apply -k $TUTORIAL_ROOT/gitops-catalog/zero-trust-workload-identity-manager/operator/overlays/stable-v1
```

The ZTWIM operands include references to the current environment. Update these values using details included in the `$APP_DOMAIN`

```shell
sed -i.bak "s/apps.example.openshift.io/$APP_DOMAIN/g" $TUTORIAL_ROOT/gitops-catalog/zero-trust-workload-identity-manager/instance/overlays/stable-v1/kustomization.yaml && rm $TUTORIAL_ROOT/gitops-catalog/zero-trust-workload-identity-manager/instance/overlays/stable-v1/kustomization.yaml.bak
```

Apply the ZTWIM operands to the cluster

```shell
kubectl apply -k $TUTORIAL_ROOT/gitops-catalog/zero-trust-workload-identity-manager/instance/overlays/stable-v1
```

#### Validating the ZTWIM Deployment

With the resources associated with ZTWIM deployed to the cluster, validate that the expected set of resources were configured appropriately.

First, check that the desired pods are running in the `zero-trust-workload-identity-manager` namespace

```shell
kubectl -n zero-trust-workload-identity-manager get pods
```

A successful result should return a pod with all containers running and _READY_ similar for the _spire-server_, _spire-spiffe-oidc-discovery-provider_ and the _zero-trust-workload-identity-manager-controller-manager_ (operator). In addition, an instance of the _spire-agent_ and _spire-spiffe-csi-driver_ originate from a DaemonSet with an instance deployed to each node in the cluster.

A healthy deployment looks similar to the following
:
```
NAME                                                              READY   STATUS    RESTARTS   AGE
spire-agent-n7lwq                                                 1/1     Running   0          51m
spire-server-0                                                    2/2     Running   0          51m
spire-spiffe-csi-driver-7v79d                                     2/2     Running   0          51m
spire-spiffe-oidc-discovery-provider-7d445b6696-jbk77             1/1     Running   0          51m
zero-trust-workload-identity-manager-controller-manager-5bt8bxw   1/1     Running   0          53m
```

One of the components that are exposed outside the cluster is an OIDC provider endpoint. Set a variable `OIDC_URL` with the value of the OIDC discovery provider

```shell
export OIDC_URL=https://$(kubectl get route -n zero-trust-workload-identity-manager spire-oidc-discovery-provider -o jsonpath='{ .spec.host }')
```

Confirm the [JWKS](https://tools.ietf.org/html/rfc7517) endpoint that is used to verify the signatures that are included within JWT's is available:

```shell
curl $OIDC_URL/keys
```

[Previous Tutorial - Identifying Security Challenges](tutorial3.md)

[Next Tutorial - Deploying Vault](tutorial5.md)

[Home](../README.md)
