#!/bin/bash

location="westeurope"
resourceGroupName="demo-github-action-uami-keyvault"
uamiName="github-uami"
keyvaultName="chgpgithubuami"
secretName="demosecret"
secretValue="Greetings from Bicep"

githubOrgOrUser="chgeuer"
githubRepo="github-action-via-user-assigned-managed-identity-to-keyvault-secret"
githubBranch="main"

az group create --location "${location}" --name "${resourceGroupName}"

az deployment group create \
  --resource-group "${resourceGroupName}" \
  --template-file keyvault.bicep \
  --parameters \
    location="${location}" \
    githubOrgOrUser="${githubOrgOrUser}" \
    githubRepo="${githubRepo}" \
    githubBranch="${githubBranch}" \
    keyvaultName="${keyvaultName}" \
    uamiName="${uamiName}" \
    secretName="${secretName}" \
    secretValue="${secretValue}" \

identityValues="$( az identity show \
    --resource-group "${resourceGroupName}" \
    --name "${uamiName}" )"
tenantId="$( echo "${identityValues}" | jq -r '.tenantId' )"
uamiClientId="$( echo "${identityValues}" | jq -r '.clientId' )"


cat <<EOF > env.txt
AZURE_TENANT_ID=${tenantId}
AZURE_UAMI_CLIENT_ID=${uamiClientId}
AZURE_KEYVAULT_NAME=${keyvaultName}
AZURE_KEYVAULT_SECRET_NAME=${secretName}
EOF

gh secret set --repo "${githubOrgOrUser}/${githubRepo}" --env-file env.txt
