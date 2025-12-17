# Create Entra App Registration + Federated Credentials for GitHub Actions OIDC
$SUBSCRIPTION_ID = 'dde8416c-6077-4b2b-b722-05bf8b782c44'
$TENANT_ID       = 'a1cc28df-8965-4e03-96cb-5d6172ff55a5'
$APP_NAME        = 'gratech-cometx-oidc'
$GITHUB_OWNER    = 'gratech-sa'
$GITHUB_REPO     = 'gratech-cometx'

az account set --subscription $SUBSCRIPTION_ID

$app = az ad app create --display-name $APP_NAME | ConvertFrom-Json
$APP_ID = $app.appId
$sp   = az ad sp create --id $APP_ID | ConvertFrom-Json
$SP_OBJECT_ID = $sp.id

az role assignment create `
  --assignee-object-id $SP_OBJECT_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Contributor" `
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Federated credentials for main and staging branches
$subjects = @(
  "repo:$GITHUB_OWNER/$GITHUB_REPO:ref:refs/heads/main",
  "repo:$GITHUB_OWNER/$GITHUB_REPO:ref:refs/heads/staging"
)

$i = 0
foreach ($sub in $subjects) {
  $name = "github-oidc-$i"
  az ad app federated-credential create `
    --id $APP_ID `
    --parameters `
  '{{
    "name": "' + $name + '",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "' + $sub + '",
    "audiences": ["api://AzureADTokenExchange"]
  }}'
  $i++
}

"AZURE_CLIENT_ID = $APP_ID"
"AZURE_TENANT_ID = $TENANT_ID"
"AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
