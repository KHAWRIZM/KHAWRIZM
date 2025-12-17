# GrAtech / Comet X — Azure + GitHub Briefing (for VS Code assistants)

> **Owner:** SULIMAN NAZAL ALSHAMMARI  
> **Primary Language:** Arabic  
> **Preferred Stack:** Azure + GitHub + Docker (GHCR)  
> **Deployment Target:** Azure Container Apps (NOT Web App)  
> **Region/RG:** eastus2 / rg-cometx-prod  
> **Domains:** `gratech.sa`, subdomains: `api.gratech.sa`, `staging.gratech.sa`  
> **Repo/Image:** `ghcr.io/gratech-sa/gratech-cometx`  

## Security & Auth (GitHub → Azure)
- Use **OIDC** via `azure/login@v2` (no client secrets).  
- GitHub Secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.  
- Federated Credential subject should target repo `gratech-sa/gratech-cometx` and branches `main`/`staging`.  

## Container Apps (Prod + Staging)
- Environments: `cae-cometx-prod`, `cae-cometx-staging`; Apps: `ca-cometx-api`, `ca-cometx-api-staging`.  
- Ingress: `external`; `targetPort` default `8080`.  
- FQDN via `az containerapp show ... --query properties.configuration.ingress.fqdn`.  

## DNS + Managed Certificates
- Subdomains use **direct CNAME** to app FQDN (`*.azurecontainerapps.io`).  
- If apex is used, use **A record** to environment static IP.  
- If root has **CAA**, add `0 issue "digicert.com"`.  

## CI/CD
- Build Docker → Trivy (fail only on **CRITICAL**) → Push to GHCR → `az containerapp update`.  

## Guardrails
- Avoid Cloudflare as intermediate CNAME for managed certs.  
- No long‑lived secrets; OIDC only.  
- Arabic responses.  
