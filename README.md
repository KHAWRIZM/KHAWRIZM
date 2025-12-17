# GraTech CometX

🚀 Modern AI-powered web application with seamless Azure deployment.

## Features

- ⚡ **React + TypeScript + Vite** - Fast, modern development
- 🎨 **Tailwind CSS** - Beautiful, responsive UI
- 🤖 **Google Generative AI** - Integrated AI capabilities
- 🐳 **Docker** - Containerized deployment
- ☁️ **Azure Ready** - One-command deployment
- 🔒 **OIDC Auth** - Secure, secretless authentication
- 🛡️ **Security First** - Automated scanning (Trivy, CodeQL)

## Quick Start

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

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide.

```powershell
# One command to rule them all
.\setup-azure.ps1
```

## Project Structure

```
gratech-cometx/
├── src/
│   ├── components/      # React components
│   ├── services/        # API services
│   ├── utils/           # Utilities
│   ├── App.tsx          # Main app
│   └── index.tsx        # Entry point
├── copilot-integration/ # Microsoft Copilot Studio
│   ├── openapi/         # API specifications
│   └── security/        # Auth configuration
├── .github/workflows/   # CI/CD pipelines
├── Dockerfile           # Container definition
└── setup-azure.ps1      # Azure setup script
```

## Tech Stack

- **Frontend:** React 18, TypeScript, Vite
- **Styling:** Tailwind CSS
- **AI:** Google Generative AI (@google/genai)
- **IDE:** Monaco Editor
- **Terminal:** XTerm.js
- **Charts:** Chart.js, Recharts
- **Deployment:** Docker, Azure Web Apps, GitHub Actions

## Environment Variables

Create `.env` file (for local development):

```env
VITE_GEMINI_API_KEY=your-api-key-here
VITE_API_URL=http://localhost:3000
```

## Scripts

```json
{
  "dev": "vite",              # Development server
  "build": "tsc && vite build", # Production build
  "preview": "vite preview"     # Preview build
}
```

## Docker

```bash
# Build image
docker build -t gratech-cometx .

# Run container
docker run -p 8080:8080 gratech-cometx

# Open in browser
open http://localhost:8080
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## License

© 2024 GraTech AI. All rights reserved.

## Links

- 🌐 Website: https://gratech.sa
- 📧 Email: support@gratech.sa
- 📦 GitHub: https://github.com/gratech-sa/gratech-cometx

---

**Built with ❤️ by GraTech AI Team**
