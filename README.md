# 🚀 GraTech CometX: AI-Powered Web Application & Azure CI/CD

<div align="center">
  <p>
    Modern AI-powered web application with seamless Azure deployment. <br/>
    تطبيق ويب حديث مدعوم بالذكاء الاصطناعي مع نشر سلس على Azure.
  </p>
</div>

GraTech CometX is a cutting-edge web application designed for intelligence, efficiency, and scalability. It integrates advanced AI capabilities with a robust frontend, all underpinned by a secure and automated deployment pipeline to Microsoft Azure.

---

## ✨ Features & Capabilities | الميزات والقدرات

-   ⚡ **React + TypeScript + Vite:** Fast, modern, and type-safe frontend development.
-   🎨 **Tailwind CSS:** Beautiful, responsive, and highly customizable UI.
-   🤖 **Google Generative AI:** Integrated capabilities for intelligent interactions and content generation.
-   🐳 **Docker:** Containerized deployment for consistent environments across development and production.
-   ☁️ **Azure Ready:** One-command deployment to Azure Container Apps or Web Apps.
-   🔒 **OIDC Auth:** Secure, secretless authentication for CI/CD workflows using GitHub Actions.
-   🛡️ **Security First:** Automated security scanning (Trivy for containers, CodeQL for code analysis) integrated into the CI/CD pipeline.
-   🌐 **Multilingual Support:** Frontend designed with Arabic/English language toggling.
-   📊 **Rich UI:** Dynamic user interface with modules for Dashboard, Chat, Live Session, Orchestrator, IDE, App Factory, and Task Management.

---

## 🎯 Project Overview & Achievements | نظرة عامة على المشروع والإنجازات

GraTech CometX provides a strong foundation for an advanced AI-powered web application.

### Current Status:
The project has achieved a high level of maturity in:
-   **Full-stack Development:** A dynamic React (TypeScript) frontend communicating with a Node.js backend (`server.cjs`).
-   **AI Integration:** Seamlessly uses Google Generative AI (`@google/genai`).
-   **Containerization:** Multi-stage Dockerfile ensures efficient, reproducible builds.
-   **Automated CI/CD:** Comprehensive GitHub Actions for building, scanning (Trivy, CodeQL), pushing to GHCR, and secure OIDC-authenticated deployment to Azure.
-   **Azure Infrastructure as Code:** `setup-azure.ps1` script automates Azure resource provisioning (App Registrations, Federated Credentials, Resource Groups, App Services).
-   **Rich Frontend Experience:** Modular UI supporting diverse views and functionalities.

### Architectural Highlights:
The application follows a modern modular single-page application architecture, deployed as a containerized service on Azure.

```mermaid
graph TD
    User --> Frontend[React Frontend (Vite, TS, Tailwind)]
    Frontend --> Backend[Node.js Backend (server.cjs)]
    Backend --> GoogleAI[Google Generative AI]
    Backend --> DataStore[(Optional) Data Storage]
    
    subgraph CI/CD & Deployment
        GitHubRepo[GitHub Repository] --> GitHubActions[GitHub Actions]
        GitHubActions --> DockerBuild[Docker Build & Scan (Trivy)]
        DockerBuild --> GHCR[GitHub Container Registry]
        GHCR --> AzureContainerApps[Azure Container Apps / Web Apps]
        GitHubActions --> AzureOIDC[Azure OIDC (Secretless Auth)]
    end

    User --> AzureContainerApps
    AzureContainerApps --> Monitoring[Azure Monitoring (Logs, Metrics)]
```

---

## 🏗️ Quick Start | بدء سريع

### Local Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Deploy to Azure

For a complete deployment guide, refer to [DEPLOYMENT.md](DEPLOYMENT.md). The `setup-azure.ps1` script automates much of the Azure setup:

```powershell
# Login to Azure (if not already logged in)
az login

# Run the setup script from the project root
.\setup-azure.ps1
```

---

## 🛠️ Tech Stack | حزمة التقنيات

-   **Frontend:** React 18, TypeScript, Vite
-   **Styling:** Tailwind CSS
-   **AI:** Google Generative AI (`@google/genai`)
-   **Backend (implied):** Node.js with Express.js (via `server.cjs`)
-   **Advanced UI Components:** Monaco Editor (for IDE), XTerm.js (for Terminal), Chart.js, Recharts (for Data Visualization).
-   **Deployment:** Docker, Azure Web Apps/Container Apps, GitHub Actions.

---

## 📚 Documentation & Guides | الوثائق والأدلة

-   [**CI-CD-GUIDE.md**](CI-CD-GUIDE.md): Detailed setup for GitHub Actions, OIDC, and security scanning.
-   [**DEPLOYMENT.md**](DEPLOYMENT.md): Comprehensive guide for deploying to Azure.
-   [**QUICKSTART.md**](QUICKSTART.md): Concise guide for CI/CD on Azure Container Apps.

---

## 🤝 Contributing | المساهمة

We welcome contributions! Please fork the repository, create a feature branch, commit your changes, and open a Pull Request.

1.  Fork the repository
2.  Create feature branch (`git checkout -b feature/your-feature-name`)
3.  Commit changes (`git commit -m 'feat: Add amazing feature'`)
4.  Push to branch (`git push origin feature/your-feature-name`)
5.  Open a Pull Request

---

## 🛣️ Remaining & Future Work | العمل المتبقي والمستقبلي

While a strong foundation is established, potential areas for further development include:

-   **Full Backend Implementation:** Expanding the functionality and scope of `server.cjs`.
-   **Advanced AI Features:** Deeper integration and fine-tuning of Google Generative AI for specific use cases.
-   **Comprehensive UX/UI Refinements:** Enhancing the Orchestrator, IDE, and App Factory modules.
-   **Scalability & Observability:** Implementing advanced Azure monitoring (e.g., Application Insights) and auto-scaling.
-   **Application-level User Management:** Integrating robust authentication and authorization within the application.
-   **Expanded Test Suite:** Developing comprehensive unit, integration, and end-to-end tests.

---

## 📜 License

© 2024 GraTech AI. All rights reserved.

---

## 🔗 Links

-   🌐 **Website:** [https://gratech.sa](https://gratech.sa)
-   📧 **Email:** [support@gratech.sa](mailto:support@gratech.sa)
-   📦 **GitHub Organization:** [https://github.com/gratech-sa/gratech-cometx](https://github.com/gratech-sa/gratech-cometx) (Original source)
    *   *Note: This repository is now maintained by @KHAWRIZM.*

---

<div align="center">
  <p>Built with ❤️ by GraTech AI Team | بُنيت بحب بواسطة فريق GraTech AI</p>
</div>