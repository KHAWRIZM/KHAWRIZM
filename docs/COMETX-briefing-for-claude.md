# GrAtech / Comet X — Azure + GitHub Briefing (for VS Code assistants)

> **Owner:** SULIMAN NAZAL ALSHAMMARI  
> **Primary Language:** Arabic  
> **Preferred Stack:** Azure + GitHub + Docker (GHCR)  
> **Deployment Target:** Azure Container Apps (NOT App Service/Web App)  
> **Regions:** Use existing Resource Group in `eastus2`  
> **Domains:** `gratech.sa`, subdomains: `api.gratech.sa`, `staging.gratech.sa`  

---

## 1) Security & Auth (GitHub → Azure)
- **Use OIDC** via `azure/login@v2`: No client secrets in GitHub.  
- Required GitHub Secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.  
- Azure: Create **App Registration** + **Service Principal** + **Federated Credential** (subject tied to repo/branch `main`).  
- Workflow must include `permissions: { id-token: write, contents: read }` and an **Azure login** step.  

### Example (Workflow snippet)
```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: actions/checkout@v4
  - name: Azure login (OIDC)
    uses: azure/login@v2
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## 2) Container Apps (Prod + Staging)
- **Environment names:** `cae-cometx-prod`, `cae-cometx-staging`  
- **App names:** `ca-cometx-api` (prod), `ca-cometx-api-staging` (staging)  
- **Ingress:** `external` enabled; set `targetPort` to the app’s listening port (e.g., `8080`).  
- **FQDNs:** retrieve via `az containerapp show ... --query properties.configuration.ingress.fqdn`.  

### DNS + Certificates (Managed)
- For **subdomains** (`api`, `staging`): create **CNAME direct** to the app FQDN (`*.azurecontainerapps.io`).  
- For **apex** (`gratech.sa`): create **A record** to the **environment static IP** if needed.  
- If root domain has **CAA**, allow DigiCert: `0 issue "digicert.com"`.  
- Managed certificates require the app to be **publicly accessible** via HTTP ingress. If access is restricted, use **BYOC (PFX)**.  

---

## 3) CI/CD (Docker + Trivy + GHCR)
- Build Docker image and **push to GHCR**: `ghcr.io/<owner>/<repo>:<tag>`.  
- Authenticate to GHCR using `docker/login-action@v3` with `username: ${{ github.actor }}` and `password: ${{ secrets.GITHUB_TOKEN }}`.  
- **Trivy scan**: fail the pipeline **only on CRITICAL** vulnerabilities.  

### Example (Build/Scan/Push)
```yaml
env:
  IMAGE_NAME: ghcr.io/${{ github.repository }}:latest

steps:
  - uses: actions/checkout@v4

  - name: Login to GHCR
    uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}

  - name: Build image
    run: docker build -t $IMAGE_NAME .

  - name: Scan with Trivy (fail only on CRITICAL)
    uses: aquasecurity/trivy-action@0.33.1
    with:
      image-ref: ${{ env.IMAGE_NAME }}
      format: 'table'
      exit-code: '1'
      ignore-unfixed: true
      severity: 'CRITICAL'

  - name: Push image
    run: docker push $IMAGE_NAME
```

---

## 4) Deploy to Container Apps (from GitHub Actions)
### Web App replacement → Container Apps update
```yaml
- name: Azure login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- name: Deploy to Container Apps (prod)
  run: |
    az containerapp update \
      --resource-group rg-cometx-prod \
      --name ca-cometx-api \
      --image ${{ env.IMAGE_NAME }}
```

---

## 5) Repo Hygiene & Security
- **Branch protection** on `main`: require PR reviews + status checks (build/deploy).  
- Enable **CodeQL** (languages per stack).  
- Enable **Dependabot** (npm/pip/docker weekly).  
- Avoid storing secrets; prefer **OIDC** for Azure auth.  

---

## 6) Preferences & Guardrails (do/don't)
**Do**
- Use Arabic in responses.  
- Use Azure **Container Apps** (NOT Web App).  
- Favor **OIDC** over client secrets.  
- Use **Azure DNS** (avoid Cloudflare unless explicitly requested).  
- Fail Trivy **only on CRITICAL**.

**Don't**
- Don’t request or store long‑lived secrets for Azure.  
- Don’t route subdomains through intermediate CNAMEs (breaks managed cert issuance).  
- Don’t mention أي ارتباط حكومي سابق.  
- لا تستخدم ألقاب مثل "أبو نزال".

---

## 7) Variables (fill before running workflows)
```env
AZURE_SUBSCRIPTION_ID=<subscription>
AZURE_TENANT_ID=<tenant>
AZURE_CLIENT_ID=<app-id>
RESOURCE_GROUP=rg-cometx-prod
ENV_PROD=cae-cometx-prod
ENV_STG=cae-cometx-staging
APP_PROD=ca-cometx-api
APP_STG=ca-cometx-api-staging
TARGET_PORT=8080
IMAGE_NAME=ghcr.io/<owner>/<repo>:latest
```

---

## 8) Troubleshooting
- Managed cert stuck in **Pending/Failed**: check **CNAME direct** to `azurecontainerapps.io`, ensure **HTTP ingress** is **external**, and add **CAA** for DigiCert if root enforces CAA.  
- GHCR push denied: ensure `docker/login-action@v3` uses `GITHUB_TOKEN` and package write permissions are enabled for the repo.  
- OIDC login failing: verify federated credential subject matches repo/branch and that workflow has `id-token: write`.

---

## 9) Quick Commands (Azure CLI)
```bash
# FQDN for app
az containerapp show -g $RESOURCE_GROUP -n $APP_PROD --query "properties.configuration.ingress.fqdn" -o tsv

# Add custom domain + Managed cert
az containerapp custom-domain add \
  --name $APP_PROD \
  --resource-group $RESOURCE_GROUP \
  --domain-name api.gratech.sa \
  --environment $ENV_PROD \
  --certificate-type Managed

# Check certificate status
az containerapp show -g $RESOURCE_GROUP -n $APP_PROD \
  --query "properties.configuration.ingress.customDomains[]"
```

---

### Notes
- This briefing intentionally **avoids secrets**. Configure secrets and variables in GitHub Actions and Azure as described above.  
- يعتمد هذا المستند على الإعدادات الحالية لمشروع Comet X وGrAtech ومعايير الأمان المفضّلة.
