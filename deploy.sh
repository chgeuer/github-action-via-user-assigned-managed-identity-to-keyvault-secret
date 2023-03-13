#!/bin/basha

location="westeurope"
resourceGroupName="demo2"
uamiName="github-uami"
keyvaultName="kvchgp123"
secretName="demosecret"
secretValue="Greetings from Bicep"

githubOrgOrUser="Microsoft-Bootcamp"
githubRepo="attendee-chgeuer"
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
