# Tutorial 4 - Deploying SPIRE

SPIRE represents the foundational component for providing identities to workloads and is at the heart for Kaya's proposed future state architecture to support Bob's application. She begins to assemble the resources to support her design in the `$TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure` directory which will be used throughout the upcoming sections.

## Deploying SPIRE using Helm

Similar to many Kubernetes components, there are several methods for which SPIRE can be installed. The most straightforward and scale method for deploying SPIRE is to use Helm and there are a set of [Helm charts](https://github.com/spiffe/helm-charts-hardened) that are available for deploying SPIRE.

Clone the Helm charts locally to obtain the content needed to deploy SPIRE

```shell
cd $TUTORIAL_ROOT
git clone -b spire-0.21.0 https://github.com/spiffe/helm-charts-hardened.git
```

With the Helm charts installed locally, deploy the Kubernetes Custom Resource Definitions

```shell
helm upgrade --install --create-namespace -n spire-mgmt spire-crds $TUTORIAL_ROOT/helm-charts-hardened/charts/spire-crds
```

We will now deploy the SPIRE Helm chart. Choose one of the below based on your environment:

> **OpenShift:**
> The custom set of Helm values is available in the file at `$TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/demo/secure/spire-helm-values.yaml`. Feel free to inspect the contents to observe some of the configurations that are being applied.
> ```shell
> helm upgrade --install --create-namespace -n spire-mgmt spire $TUTORIAL_ROOT/helm-charts-hardened/charts/spire -f $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/spire/spire-helm-values.yaml --set global.spire.namespaces.create=true --set global.spire.trustDomain=$APP_DOMAIN --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values.yaml --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values-ingress.yaml --render-subchart-notes --debug
> ```

> **Kind:**
> The custom set of Helm values is available in the file at `$TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/demo/secure/spire-helm-kind-values.yaml`. Feel free to inspect the contents to observe some of the configurations that are being applied.
> ```shell
> helm upgrade --install --create-namespace -n spire-mgmt spire $TUTORIAL_ROOT/helm-charts-hardened/charts/spire -f $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/spire/spire-helm-kind-values.yaml --set global.spire.namespaces.create=true --set global.spire.trustDomain=$APP_DOMAIN --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values.yaml --values $TUTORIAL_ROOT/helm-charts-hardened/examples/tornjak/values-ingress.yaml --render-subchart-notes --debug
> ```

### Validating the SPIRE Deployment

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

One of the components that are exposed outside the cluster is an OIDC provider endpoint. Confirm the [JWKS](https://tools.ietf.org/html/rfc7517) endpoint that is used to verify the signatures that are included within JWT's is available. Choose one of the below commands based on your environment:

> **OpenShift:**
> ```shell
> curl https://$(kubectl get ingress -n spire-server  spire-spiffe-oidc-discovery-provider -o jsonpath='{ .spec.rules[*].host }')/keys
> ```

> **Kind:**
> Because we are using self-signed certificate for ingress, we need to use the `--cacert` flag with the certificate we generated prior at `$TUTORIAL_ROOT/wildcard-tls.crt`:`
> ```shell
> curl --cacert $TUTORIAL_ROOT/wildcard-tls.crt https://$(kubectl get ingress -n spire-server  spire-spiffe-oidc-discovery-provider -o jsonpath='{ .spec.rules[*].host }')/keys
> ```

The final component of the SPIFFE deployment that should be validated is that Tornjak is running and available. Tornjak is a project that enables the management of SPIFFE identities managed by SPIRE.

Obtain the URLs of the Tornjak endpoint:

```shell
echo  https://$(kubectl get ingress -n spire-server  spire-tornjak -o jsonpath='{ .spec.rules[*].host }') 
echo  https://$(kubectl get ingress -n spire-server  spire-tornjak-frontend -o jsonpath='{ .spec.rules[*].host }') 
```

Launch a browser and navigate to the URLs obtained by the output from the previous command to access Tornjak. The first URL is the backend, which should simply display a message `Welcome to the Tornjak Backend!`. 

The second URL goes to the Tornjak UI. The landing page provides a list of the nodes in the Kubernetes cluster. By clicking on the _Entries_ button on the navigation bar lists the workloads that have identities that have been issued by SPIRE. These identities will be key in Kaya's longterm architecture which will enable accessing protected resources stored within Vault which will be deployed and configured in the next tutorial exercise.

> [!NOTE]
> You may need to "Accept Risk and Continue" if you are working with the local Kind deployment, as we are using a self-signed certificate.
> Additionally, because the frontend relies on the backend, in this case, you must go to the backend URL first and "Accept Risk and Continue" so that the frontend can successfully retrieve data from the backend


[Previous Tutorial - Identifying Security Challenges](tutorial3.md)

[Next Tutorial - Deploying Vault](tutorial5.md)

[Home](../README.md)
