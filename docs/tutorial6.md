# Tutorial 6 - Accessing Resources Stored in Vault using SPIRE

Now that all of the components supporting Kaya's future state architecture are in place, let's discuss how the Python application will migrate from the existing method of using credentials stored in a ConfigMap to access the database and instead obtain credentials from the KV Secret in Vault.

## Understanding SPIRE Workload Identities

SPIRE supports an integration with Kubernetes to provide identities to workloads running on the platform. As Kubernetes resources are created and destroyed within Kubernetes, these Entities are registered within SPIRE. Workloads interact with SPIRE using the Workload API that is exposed as a Linux Socket that can be consumed as a directory mount within the container. Containers can access this socket by either directly gaining access to resources running on each Kubernetes Node using a `hostpath` [Volume](https://kubernetes.io/docs/concepts/storage/volumes) type or making use of a `csi` representing utilizing the [Container Storage Interface (CSI)](https://github.com/container-storage-interface/spec).

SPIRE includes support for CSI volumes and it provides several advantages to mounting directories directly from the underlying host, including lifecycle management and improved security. Once the socket is made available to workloads, they can use this entrypoint as a way to obtain an SVID. An SVID can either take the form of a JWT or an X.509 certificate. For the purpose of this tutorial, JWT's will be used for authentication purposes.

Once a JWT has been obtained from SPIRE, the JWT can then be used to authenticate with Vault to retrieve access to stored resources. Let's see this in action by deploying a sample workload to Kubernetes that will utilize SPIRE identities to communicate with Vault.

### Debug SPIRE Interaction

To better understand how identities are obtained from SPIRE and used to obtain resources from Vault, create a new Deployment called `spire-debug` in the `workload-identity-tutorial` namespace to enable debugging the interaction with each of these components.

```shell
envsubst < $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/apps/spire-debug.yaml | kubectl apply -f -
```

This Deployment enables the use of SPIRE identities by mounting the SPIRE socket from the `csi` volume as shown below:

```yaml
...
volumes:
  - name: spiffe-workload-api
    csi:
      driver: "csi.spiffe.io"
      readOnly: true
...
```

Verify that the `spire-debug` pod is up and running:

```shell
kubectl -n workload-identity-tutorial get pod -l=app=spire-debug
```

Obtain a remote shell in the pod created by the `spire-debug` Deployment using the following command:

```shell
kubectl -n workload-identity-tutorial exec -it $(kubectl -n workload-identity-tutorial get pod -l=app=spire-debug -o jsonpath='{ .items[*].metadata.name}') -- bash
```

Once inside the container, A SPIFFE identity can be obtained using the `spire-agent` CLI which is included within the container. The location SPIRE socket within the container is exposed via the `SOCKETFILE` environment variable.

Execute the following command to obtain a JWT using the `spire-agent` CLI

```shell
/opt/spire/bin/spire-agent api fetch jwt -audience vault -socketPath $SOCKETFILE 
```

Several values provided within the response. To extract just the JWT, execute teh followin command to store the result in the environment `IDENTITY_TOKEN` environment variable.

```shell
export IDENTITY_TOKEN=$(/opt/spire/bin/spire-agent api fetch jwt -audience vault -socketPath $SOCKETFILE | sed -n '2p' | xargs)
```

Print the value of the JWT stored in the `IDENTITY_TOKEN` environment variable

```shell
echo $IDENTITY_TOKEN
```

A JWT is a digitally signed encoded JSON object which enables the transmission of information between parties. Properties within a JWT are stored as `claim` and represent both assets defined by the JWT specification as well as customized parameters (custom claims).

There are a number of tools that can be used to decode the contents of a JWT, one of which being jwt.io. Navigate to [https://jwt.io](https://jwt.io) in a web browser and paste in the content of JWT the SPIRE JWT token. The contents of the token are similar to the following:

```json
{
  "aud": [
    "vault"
  ],
  "exp": 1719353179,
  "iat": 1719349579,
  "iss": "https://oidc-discovery.apps.cluster-xxxxx.xxxxx.sandboxxxxx.opentlc.com",
  "sub": "spiffe://apps.cluster-xxxxx.xxxxx.sandboxxxxx.opentlc.com/ns/workload-identity-tutorial/sa/py"
}
```

Let's break down the contents of the JWT above

* `aud` - List of intended recipients for the JWT; in this case `vault
* `ext` - Expiration timestamp (in seconds since epoch)
* `iat` - Timestamp the JWT was issued at (in seconds since epoch)
* `iss` - Issuer of the JWT
* `sub` - Subject who the token refers to

The subject field represents the workload specifically and can be broken down into the following parts:

* `spiffe://` - SPIFFE protocol
* `apps.cluster-xxxxx.xxxxx.sandboxxxxx.opentlc.com` - The SPIFFE [Trust Domain](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts) representing the Kubernetes cluster (`APP_DOMAIN`)
* `ns/workload-identity-tutorial` - Kubernetes namespace
* `sa/default` - Service account associated with the workload

With an understanding of how JWT's cant be obtained from SPIRE and their composition, use the JWT stored in the `IDENTITY_TOKEN` environment variable to obtain an access token from Vault:

```shell
curl --max-time 10 -s --request POST --data '{ "jwt": "'"${IDENTITY_TOKEN}"'", "role": "'"${ROLE}"'"}' "${VAULT_ADDR}"/v1/auth/jwt/login | jq
```

Inspect the contents of the returned access token. In particular note the `dbpolicy` is included in the `policies` property and the `dbrole` is defined under the `metadata` property which are both underneath the `auth` property confirming that the JWT token that was obtained from SPIRE is mapping properly in value.

The components that connect both SPIFFE and Vault in the JWT are the `iss` and `sub` fields. When setting up JWT authentication, the value of the OIDC provider was specified to match the `iss` field of the JWT. The `dbrole` enforces that the `aud` field equals `vault` and the `sub` field matches the `spiffe://${APP_DOMAIN}/ns/workload-identity-tutorial/sa/*` glob pattern enabling several different entities to access protected resources within Vault.

Set the `VAULT_TOKEN` environment variable to represent that access token:

```shell
VAULT_TOKEN=$(curl --max-time 10 -s --request POST --data '{ "jwt": "'"${IDENTITY_TOKEN}"'", "role": "'"${ROLE}"'"}' "${VAULT_ADDR}"/v1/auth/jwt/login | jq -r  '.auth.client_token')
```

### Obtaining Secrets Stored in Vault

The final step is to make use of the Vault access token to retrieve the contents of the configuration file containing the database credentials from the Vault KV secret store.

Make a request to the to Vault via the API to obtain the contents of a resource stored in the Vault KV secret store at the path `secret/data/db-config/config.ini`. Since the contents were base64 encoded to facilitate storage within the KV secret store, decode the base64 encoded result to confirm the contents represent the database configuration file:

```shell
curl --max-time 10 -s -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/data/db-config/config.ini | jq -r ".data.data.sha" | openssl base64 -d
```

A successful query will obtain the database configuration file and print the contents confirming the use of workload identity to obtain resources stored within Vault.

Exit the container by specifying the `exit` command:

```shell
exit
```

Remove the debugging deployment to clean up the testing resources from the `workload-identity-tutorial` namespace:

```shell
kubectl delete -f $TUTORIAL_ROOT/cloudnativesecuritycon-workload-identity-tutorial/resources/secure/apps/spire-debug.yaml
```

Proceed to the next tutorial exercise to implement the changes necessary within the Python application.

[Previous Tutorial - Deploying Vault](tutorial5.md)

[Next Tutorial - Securing the Python Application](tutorial7.md)

[Home](../README.md)
