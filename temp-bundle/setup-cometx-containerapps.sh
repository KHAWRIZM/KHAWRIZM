#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="dde8416c-6077-4b2b-b722-05bf8b782c44"
LOCATION="eastus2"
RG="rg-cometx-prod"
ENV_PROD="cae-cometx-prod"
ENV_STG="cae-cometx-staging"
APP_PROD="ca-cometx-api"
APP_STG="ca-cometx-api-staging"
TARGET_PORT=5173
IMAGE_PROD="ghcr.io/gratech-sa/gratech-cometx:latest"
IMAGE_STG="ghcr.io/gratech-sa/gratech-cometx:staging"
DOMAIN_ZONE="gratech.sa"
DOMAIN_PROD="api.gratech.sa"
DOMAIN_STG="staging.gratech.sa"

az account set --subscription "$SUBSCRIPTION_ID"
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

az containerapp env create -g "$RG" -n "$ENV_PROD" -l "$LOCATION"
az containerapp env create -g "$RG" -n "$ENV_STG"  -l "$LOCATION"

echo "== ENV PROD (domain/ip) =="
az containerapp env show -g "$RG" -n "$ENV_PROD" --query "{{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}}" -o json

echo "== ENV STAGING (domain/ip) =="
az containerapp env show -g "$RG" -n "$ENV_STG"  --query "{{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}}" -o json

az containerapp create -g "$RG" -n "$APP_PROD" --environment "$ENV_PROD" --image "$IMAGE_PROD" --ingress external --target-port $TARGET_PORT
az containerapp create -g "$RG" -n "$APP_STG"  --environment "$ENV_STG"  --image "$IMAGE_STG"  --ingress external --target-port $TARGET_PORT

APP_PROD_FQDN=$(az containerapp show -g "$RG" -n "$APP_PROD" --query "properties.configuration.ingress.fqdn" -o tsv)
APP_STG_FQDN=$(az containerapp show -g "$RG" -n "$APP_STG"  --query "properties.configuration.ingress.fqdn" -o tsv)

echo "PROD FQDN: $APP_PROD_FQDN"; echo "STG FQDN: $APP_STG_FQDN"

az containerapp custom-domain add --name "$APP_PROD" --resource-group "$RG" --domain-name "$DOMAIN_PROD" --environment "$ENV_PROD" --certificate-type Managed
az containerapp custom-domain add --name "$APP_STG"  --resource-group "$RG" --domain-name "$DOMAIN_STG"  --environment "$ENV_STG"  --certificate-type Managed

echo "CNAME api.gratech.sa -> $APP_PROD_FQDN"; echo "CNAME staging.gratech.sa -> $APP_STG_FQDN"
echo 'CAA (root): 0 issue "digicert.com"'
