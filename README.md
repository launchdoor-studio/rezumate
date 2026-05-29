<div align="center">
  <img src="app/static/img/favicon.png" alt="Rezumate Logo" width="100" height="100">
  
  # Rezumate
  
  **From Raw Resume to Hired.** A professional-grade, AI-powered tool for analyzing, comparing, and ranking resumes against job descriptions.

  ![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)
  ![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
  ![Turso](https://img.shields.io/badge/Database-Turso-00A3E0?logo=sqlite&logoColor=white)
  ![Vercel](https://img.shields.io/badge/Deployment-Vercel-000000?logo=vercel&logoColor=white)
  ![Groq](https://img.shields.io/badge/AI-Groq-F55036)
</div>

## ✨ Pro Features
- **🎯 Precision Scoring:** Calibrated ATS scanning using Llama 3.3 70B.
- **📊 Structured Dashboard:** Visualizes skill gaps, strengths, and fit levels.
- **📄 High-Fidelity Parsing:** Layout-aware PDF extraction with `pdfplumber`.
- **💾 Persistent History:** Powered by **Turso** (SQLite at the edge) for zero-cost persistence.
- **🤖 Contextual Chat:** Deep-dive into resume improvements with a persistent AI coach.

## 🚀 Quick Start (Zero-Cost Deployment)

### 1. Prerequisites
- [Groq API Key](https://console.groq.com/)
- [Turso CLI](https://docs.turso.tech/cli) (Optional for local, required for prod)

### 2. Local Setup
```bash
# Install dependencies
uv sync

# Run the application
uv run dev
```
The app will automatically use a local `rezumate.db` if no `DATABASE_URL` is provided.

### 3. Production Deployment (Vercel + Turso)
1. **Create Turso DB:** `turso db create rezumate`
2. **Get Credentials:** 
   - URL: `turso db show rezumate --url`
   - Token: `turso db tokens create rezumate`
3. **Deploy to Vercel:**
   - Push to GitHub.
   - Connect to Vercel.
   - Add Env Vars: `DATABASE_URL` (your Turso URL) and `GROQ_API_KEY`.

## 🛠 Tech Stack
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL in production, SQLite fallback for local dev
- **AI:** LangChain + Groq (Llama 3.3 70B)
- **Mobile:** Expo + React Native

## 📱 Mobile App
```bash
# Backend, from repo root
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Mobile, from another terminal
cd mobile
npm install
npm run ios
```

The mobile app uses `EXPO_PUBLIC_API_BASE_URL` from `mobile/.env`. For the iOS simulator on the same Mac, use `http://127.0.0.1:8000`.

## License
MIT License
