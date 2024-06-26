# Tutorial 7 - Securing the Python Application

The last remaining step towards achieving Kaya's vision for enabling Bob's Python application to operate securely and make use of workload identity using SPIRE is to update the application itself.

In order to achieve the same result to obtain the configuration file containing the database credentials from Vault using the SPIRE JWT, an [Init Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers) that orchestrates these steps prior to starting the primary Python container. The resulting configuration file will be deposited within an `emptyDir` volume that is shared between the two containers so that once the init container completes and the application container starts, it will be able to use the configuration file in the same way as when it was stored at rest within the `ConfigMap` within the Kubernetes cluster.

First, remove the `db-config` ConfigMap containing the configuration file for the database since the contents will be obtained moving forward from Vault.

```shell
kubectl delete configmap -n workload-identity-tutorial db-config
```

Now, apply the updated set of Python application manifests to the cluster:

```shell
envsubst < $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/apps/py.yaml | kubectl apply -f -
```

The updated `Deployment` will trigger a new version of the Python application to be created. It will first terminate the existing version and create a new Pod with the updated configuration. Confirm the new pod was created and has a status of `Running`:

```shell
kubectl get pods -n workload-identity-tutorial -l=app=py
```

Finally, navigate to the URL exposed by the application which can be accessed at the following location in a web browser:

```shell
echo https://$(kubectl -n workload-identity-tutorial get ingress py -o jsonpath='{ .spec.rules[*].host }')
```

If the application continues to display a list of movie titles that are sourced from the MySQL database, Kaya's ambitious goal of introducing workload identity to harden the security posture by eliminating the storage or hardcoded credentials at rest to support Bob's Python application was a success!

[Previous Tutorial - Accessing Resources Stored in Vault using SPIRE](tutorial6.md)

[Next Tutorial - Conclusion](tutorial8.md)

[Home](../README.md)
