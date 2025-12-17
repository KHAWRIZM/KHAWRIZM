# 📚 GraTech CometX - Documentation

This directory contains documentation and configuration files for the GraTech CometX project.

## 📁 Files

### Claude AI Context Files

- **[COMETX-briefing-for-claude.md](COMETX-briefing-for-claude.md)**
  - Complete briefing for Claude Sonnet AI
  - Contains project overview, architecture, and best practices
  - Use this as context when working with Claude in VS Code

- **[claude-grounding-directives.txt](claude-grounding-directives.txt)**
  - System prompt directives for Claude
  - Ensures accurate responses without hallucination
  - Copy this to Claude's System Prompt field

## 🎯 How to Use with Claude

### Option 1: Full Context (Recommended)
1. Open `COMETX-briefing-for-claude.md`
2. Copy the entire content
3. Paste it in your conversation with Claude
4. Ask: "Based on this briefing, help me with [your task]"

### Option 2: System Prompt
1. Open `claude-grounding-directives.txt`
2. Copy the content
3. Add it to Claude's System Prompt settings
4. Start your conversation normally

## 🔐 Key Policies

- ✅ **OIDC Authentication** - No stored secrets
- ✅ **Container Apps** - Scalable, modern infrastructure
- ✅ **GHCR** - GitHub Container Registry for images
- ✅ **Trivy** - Security scanning (fail on CRITICAL only)
- ✅ **Managed Certificates** - Free SSL with Azure

## 🌐 Resources

- [Azure OIDC with GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
- [Container Apps Custom Domains](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates)
- [GitHub Container Registry](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy-action)

## 📝 Next Steps

1. Review the briefing documents
2. Set up Azure infrastructure using scripts in root directory
3. Configure GitHub Secrets
4. Push code to trigger CI/CD

---

**Built with ❤️ by GraTech AI Team**
