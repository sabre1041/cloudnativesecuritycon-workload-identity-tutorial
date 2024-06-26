#!/bin/bash

ROLE="dbrole"
POLICY="dbpolicy"
#OIDC_URL=${OIDC_URL:-$1}
APP_DOMAIN=${APP_DOMAIN:-1}
ROOT_TOKEN=${ROOT_TOKEN:-$2}
VAULT_ADDR=${VAULT_ADDR:-$3}
export VAULT_ADDR=$VAULT_ADDR
export ROOT_TOKEN=$ROOT_TOKEN
export OIDC_URL=https://oidc-discovery.${APP_DOMAIN}
# remove any previously set VAULT_TOKEN, that overrides ROOT_TOKEN in Vault client
export VAULT_TOKEN=

## create help menu:
helpme()
{
  cat <<HELPMEHELPME

Syntax: ${0} <APP_DOMAINL> <ROOT_TOKEN> <VAULT_ADDR>
Where:
  APP_DOMAIN  - execute (kubectl get cm -n openshift-config-managed console-public -o go-template="{{ .data.consoleURL }}" | sed 's@https://@@; s/^[^.]*\.//')
  ROOT_TOKEN  - Vault root token to setup the plugin (optional, if set as env. var)
  VAULT_ADDR  - Vault address in format http://vault.server:8200 (optional, if set as env. var)

HELPMEHELPME
}

setupVault()
{
  vault login -no-print "${ROOT_TOKEN}"
  RT=$?
  if [ $RT -ne 0 ] ; then
     echo "ROOT_TOKEN is not correctly set"
     echo "ROOT_TOKEN=${ROOT_TOKEN}"
     echo "VAULT_ADDR=${VAULT_ADDR}"
     exit 1
  fi

  # Enable JWT authentication
  vault auth enable jwt
  RT=$?
  if [ $RT -ne 0 ] ; then
     echo " 'vault auth enable jwt' command failed"
     echo "jwt maybe already enabled?"
     read -n 1 -s -r -p 'Press any key to continue'
     #exit 1
  fi


  # Connect OIDC - Set up our OIDC Discovery URL,
  vault write auth/jwt/config oidc_discovery_url=$OIDC_URL default_role=“$ROLE”
  RT=$?
  if [ $RT -ne 0 ] ; then
     echo " 'vault write auth/jwt/config oidc_discovery_url=' command failed"
     echo "jwt maybe already enabled?"
     read -n 1 -s -r -p 'Press any key to continue'
     #exit 1
  fi

  # Define a policy my-mars-policy that will be assigned to a marsrole role that we’ll create in the next step.
  cat > $POLICY.hcl <<EOF
  path "secret/data/db-config/*" {
     capabilities = ["read"]
  }
EOF

  # write policy
  vault policy write $POLICY ./$POLICY.hcl

# bound_subject does not allow using wildcards
# so we use bound_claims instead
  cat > role.json <<EOF
  {
      "role_type":"jwt",
      "user_claim": "sub",
      "bound_audiences": "vault",
      "bound_claims_type": "glob",
      "bound_claims": {
        "sub":"spiffe://${APP_DOMAIN}/ns/workload-identity-tutorial/sa/py"
      },
      "token_ttl": "24h",
      "token_policies": "$POLICY"
  }
EOF

  vault write auth/jwt/role/$ROLE -<role.json
  vault read auth/jwt/role/$ROLE
}

footer() {

  cat << EOF
create the secret in Vault (e.g.):
   vault kv put secret/db-config.json @config.json

Then start the workload container and get inside:

  kubectl -n default create -f examples/spire/sidecar.yaml
  kubectl -n default exec -it <container id> -- sh

Once inside:
  # install jq parser
  apk add jq

  # get the JWT token, and export it as JWT env. variable:
  bin/spire-agent api fetch jwt -audience vault -socketPath /run/spire/sockets/spire-agent.sock

  # setup env. variables:
  export JWT=
  export ROLE=$ROLE
  export VAULT_ADDR=$VAULT_ADDR

  # using this JWT to login with vault and get a token:
EOF

 echo "  curl --max-time 10 -s -o out --request POST --data '{" '"jwt": "'"'"'"${JWT}"'"'"'", "role": "'"'"'"${ROLE}"'"'"'"}'"' "'"${VAULT_ADDR}"/v1/auth/jwt/login'
 echo # empty line
 echo "  # get the client_token from the response"
 echo '  TOKEN=$(cat out | jq -r ' "'.auth.client_token')"
 echo '  curl -s -H "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/secret/data/db-config.json' " | jq -r '.data.data'"
}

# validate the arguments
if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]] ; then
  helpme
  exit 0
fi

# Make sure the OIDC_URL parameter is set
if [[ "$OIDC_URL" == "" ]] ; then
  echo "OIDC_URL must be set"
  helpme
  exit 1
fi

# when paramters provider, overrid the env. variables
if [[ "$3" != "" ]] ; then
  export OIDC_URL="$1"
  export ROOT_TOKEN="$2"
  export VAULT_ADDR="$3"
elif [[ "$ROOT_TOKEN" == "" || "$VAULT_ADDR" == "" ]] ; then
  echo "ROOT_TOKEN and VAULT_ADDR must be set"
  helpme
  exit 1
fi

setupVault
footer
