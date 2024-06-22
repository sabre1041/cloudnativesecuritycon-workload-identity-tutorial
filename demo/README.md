# Workload Identity Tutorial for Cloud Native Security Con 2024

## Initialize the Demo Cluster
Create a One Node OpenShift Cluster (4.14), size m5a.2xlarge  here [https://demo.redhat.com/catalog](https://demo.redhat.com/catalog)

Assuming we have the Web Terminal  already setup, let's get to the demo!

## Obtain the deployment scripts for the demo

```console
git clone -b dev https://github.com/sabre1041/cloudnativesecuritycon-workload-identity-tutorial.git
cd cloudnativesecuritycon-workload-identity-tutorial/demo/
```

## Obtain APP_DOMAIN (Ingress information)

~~For OpenShift:~~


> ~~export APP_DOMAIN=$(oc get cm -n openshift-config-managed console-public -o go-template="{{ .data.consoleURL }}" | sed 's@https://@@; s/^[^.]*\.//')~~
> ~~echo $APP_DOMAIN~~

For Kubernetes:
```console
export APP_DOMAIN=apps.$(kubectl get dns cluster -o jsonpath='{ .spec.baseDomain }')
echo $APP_DOMAIN
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

### Deploy MySql

This command deploys, initializes MySql service and then populates it with the sample entries.

```console
kubectl -n demo apply -f app/db-node.yaml
```

### Deploy the Application

```console
envsubst < app/apps.yaml | kubectl apply -n demo -f - 
```

Verify the app was deployed correctly.
Get the URL from the command below and open in the browser:

```console
export APP=$(kubectl -n demo get ingress py -o jsonpath='{ .spec.rules[*].host }')
echo "https://$APP"
```

## Secure the Environment

### Obtain SPIRE helm charts

Get the SPIRE helm-charts-harden from SPIFFE repository: 

```console
cd
git clone -b spire-0.21.0 https://github.com/spiffe/helm-charts-hardened.git
cd helm-charts-hardened/
```

Deploy the SPIRE CRDs:

```console
helm upgrade --install --create-namespace -n spire-mgmt spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/
```

Assuming the env. variable `APP_DOMAIN` is still set, deploy the SPIRE to this environment:

```console
helm upgrade --install --create-namespace -n spire-mgmt spire charts/spire -f ../cloudnativesecuritycon-workload-identity-tutorial/demo/secure/spire-helm-values.yaml --set global.spire.namespaces.create=true --set global.spire.trustDomain=$APP_DOMAIN --values examples/tornjak/values.yaml --values examples/tornjak/values-ingress.yaml --render-subchart-notes --debug
```

This might take a minute or two to complete.

Validate the deployment completed successfully:

```console
kubectl -n spire-server get po -w
```

Check if the external access to SPIRE services was created (Ingress):

```console
kubectl -n spire-server get ingress 
```

Test access to the OIDC Discovery Service: 

```console
curl https://$(kubectl get ingress -n spire-server  spire-spiffe-oidc-discovery-provider -o jsonpath='{ .spec.rules[*].host }')/keys
```

Since Tornjak is a UI interface for SPIRE, open the service with the browser: 

```console
echo  https://$(kubectl get ingress -n spire-server  spire-tornjak-frontend -o jsonpath='{ .spec.rules[*].host }')/entries 
```

### Deploy Vault 
Create a namespace called `vault` for the Vault service:

```console
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: vault
EOF
```

Deploy Vault service: 

```console
cd 
cd cloudnativesecuritycon-workload-identity-tutorial/demo/

envsubst < secure/vault.yaml | kubectl apply -n vault -f - 
```

Once Vault deployed, set the env. variables in your local console where you have the deployment scripts: 

```console
kubectl -n vault wait --for=condition=ready --timeout=300s pod $(kubectl -n vault get po | grep vault-| awk '{print $1}')

export VAULT_ADDR=https://vault-vault.$APP_DOMAIN
export ROOT_TOKEN=$(kubectl -n vault logs $(kubectl -n vault get po | grep vault-| awk '{print $1}') | grep Root | cut -d' ' -f3); echo "export ROOT_TOKEN=$ROOT_TOKEN"
```

Test the remote connection to vault:

```console
curl  $VAULT_ADDR/v1/sys/health
```

A response similar to the following should be returned

```json
{"initialized":true,"sealed":false,"standby":false,"performance_standby":false,"replication_performance_mode":"disabled","replication_dr_mode":"disabled","server_time_utc":1718150997,"version":"1.7.0","cluster_name":"vault-cluster-ea45aecd","cluster_id":"1e4b5395-f9d7-92f4-f2ff-d16cd3edec7b"}
```

Now test the login to Vault (vault client required):

```console
vault login -no-print "${ROOT_TOKEN}"
```

Once the Vault instance is up we need to configure Vault to accept SPIRE identity tokens and setup access policies. We have a script `secure/vault-oidc.sh` to automate this process. Assuming we already setup the required env. variables (APP_DOMAIN, ROOT_TOKEN, and VAULT_ADDR; see above) simply run the script: 

```console
./secure/vault-oidc.sh
```

### Pushing the DB credentials to Vault

Now we can push our secret files to Vault. For this example we will be using a file:
[secure/config.ini](secure/config.ini) (for python)
Where the userid and password must match the DB values used in our sample configuration [secure/db-node.yaml](secure/db-node.yaml)

Since this file is not in JSON format in cannot be directly inject to Vault.
We can use a trick to encode it and store its encoded value as a key:

```console
SHA64=$(openssl base64 -in secure/config.ini )
vault kv put secret/db-config/config.ini sha="$SHA64"
# then to retrieve it:
vault kv get -field=sha secret/db-config/config.ini | openssl base64 -d
```

### Demonstrate the Sidecar Functionality

Start the stand-alone sidecar. _Make sure the env. variables are still set_: 

```console
envsubst < secure/sidecar.yaml | kubectl apply -n demo -f -
```

Get inside the sidecar container, make sure to replace the `<pod_id>` with the correct value:

```console
kubectl -n demo get pods
kubeclt -n demo exec -it <pod_id> -- bash
```

Once inside the container, you can make the following calls:

Get this pod's SPIFFE identity in form of the [JWT](jwt.io) token: 

```console
/opt/spire/bin/spire-agent api fetch jwt -audience vault -socketPath $SOCKETFILE 

# store the pod identity:
export IDENTITY_TOKEN=$(/opt/spire/bin/spire-agent api fetch jwt -audience vault -socketPath $SOCKETFILE | sed -n '2p' | xargs)
```

Use this identity to get access token from Vault:

```console
curl --max-time 10 -s --request POST --data '{ "jwt": "'"${IDENTITY_TOKEN}"'", "role": "'"${ROLE}"'"}' "${VAULT_ADDR}"/v1/auth/jwt/login

# store the Vault access token:
VAULT_TOKEN=$(curl --max-time 10 -s --request POST --data '{ "jwt": "'"${IDENTITY_TOKEN}"'", "role": "'"${ROLE}"'"}' "${VAULT_ADDR}"/v1/auth/jwt/login | jq -r  '.auth.client_token')
```

Use the Vault access token to obtain the MySql config. Remember it is encoded, so we need to decode it:

```console
curl --max-time 10 -s -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/data/db-config/config.ini | jq -r ".data.data.sha" | openssl base64 -d
```

This data now can be put in a temporary file that is used by the App for establishing connection to MySql service.

### Redeploy the App with the Sidecar

Now were are ready to redeploy the App. It will start a Sidecar as container init.
Process similar to above will retrieve the MySql config and store it in the file, before starting the main App container.

```console
envsubst < secure/apps.yaml | kubectl apply -n demo -f -
```

Wait until the App restarts

```console
kubectl -n demo get po -w
```

Then verify the app was deployed correctly.
Get the URL from the command below and open in the browser:

```console
export APP=$(kubectl -n demo get ingress py -o jsonpath='{ .spec.rules[*].host }')
echo "https://$APP"
```
