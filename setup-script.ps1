#!/bin/bash

# ============================================================================
# RenderFlow Repository Setup Script
# Run this script in your cloned repository to create all file
# ============================================================================

set -e  # Exit on error

echo "🚀 Setting up RenderFlow repository..."

# ============================================================================
# Create Directory Structure
# ============================================================================

echo "📁 Creating directory structure..."

mkdir -p .github/workflows
mkdir -p backend/{tests,logs}
mkdir -p frontend/{app,components/ui,lib,public}
mkdir -p database/migrations
mkdir -p comfyui/{models/{checkpoints,loras,vae,embeddings},workflows,custom_nodes,output}
mkdir -p docs
mkdir -p scripts

# Create .gitkeep files for empty directories
touch backend/logs/.gitkeep
touch database/migrations/.gitkeep
touch comfyui/models/checkpoints/.gitkeep
touch comfyui/models/loras/.gitkeep
touch comfyui/models/vae/.gitkeep
touch comfyui/models/embeddings/.gitkeep
touch comfyui/custom_nodes/.gitkeep
touch comfyui/output/.gitkeep

echo "✅ Directory structure created"

# ============================================================================
# Root Configuration Files
# ============================================================================

echo "📝 Creating root configuration files..."

# .env.example
cat > .env.example << 'EOF'
# Root environment variables for docker-compose
POSTGRES_PASSWORD=changeme_secure_password
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
S3_BUCKET=renderflow-images
AWS_REGION=us-east-1
SECRET_KEY=change-this-secure-key
ALLOWED_ORIGINS=http://localhost:3000
EOF

# docker-compose.prod.yml
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    restart: always
    environment:
      POSTGRES_DB: renderflow
      POSTGRES_USER: renderflow_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - renderflow-net

  redis:
    image: redis:7-alpine
    restart: always
    volumes:
      - redis_data:/data
    networks:
      - renderflow-net

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: always
    environment:
      - DATABASE_URL=postgresql://renderflow_user:${POSTGRES_PASSWORD}@postgres:5432/renderflow
      - REDIS_URL=redis://redis:6379/0
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - S3_BUCKET=${S3_BUCKET}
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - postgres
      - redis
    networks:
      - renderflow-net
    command: gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    restart: always
    environment:
      - NEXT_PUBLIC_API_URL=https://api.yourdomain.com
    networks:
      - renderflow-net

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - backend
      - frontend
    networks:
      - renderflow-net

volumes:
  postgres_data:
  redis_data:

networks:
  renderflow-net:
    driver: bridge
EOF

echo "✅ Root files created"

# ============================================================================
# Backend Files
# ============================================================================

echo "📝 Creating backend files..."

# backend/database.py
cat > backend/database.py << 'EOF'
"""Database configuration and session management"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """Database dependency for FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

# backend/s3_storage.py
cat > backend/s3_storage.py << 'EOF'
"""S3/R2 Storage utilities"""
import boto3
from botocore.exceptions import ClientError
import os
from typing import Optional

class StorageClient:
    def __init__(self):
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
            region_name=os.getenv('AWS_REGION', 'us-east-1'),
            endpoint_url=os.getenv('S3_ENDPOINT_URL')
        )
        self.bucket = os.getenv('S3_BUCKET')
    
    async def upload_image(self, image_data: bytes, key: str) -> Optional[str]:
        """Upload image to S3/R2 and return URL"""
        try:
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=image_data,
                ContentType='image/png'
            )
            
            if os.getenv('S3_ENDPOINT_URL'):
                url = f"{os.getenv('S3_ENDPOINT_URL')}/{self.bucket}/{key}"
            else:
                url = f"https://{self.bucket}.s3.{os.getenv('AWS_REGION')}.amazonaws.com/{key}"
            
            return url
        except ClientError as e:
            print(f"Error uploading to S3: {e}")
            return None
EOF

# backend/tests/__init__.py
touch backend/tests/__init__.py

# backend/tests/test_api.py
cat > backend/tests/test_api.py << 'EOF'
"""API endpoint tests"""
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert "status" in response.json()

def test_get_profiles():
    response = client.get("/api/profiles")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
EOF

echo "✅ Backend files created"

# ============================================================================
# Frontend Files
# ============================================================================

echo "📝 Creating frontend files..."

# frontend/next.config.js
cat > frontend/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    domains: ['localhost', 's3.amazonaws.com'],
  },
}

module.exports = nextConfig
EOF

# frontend/tsconfig.json
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# frontend/postcss.config.js
cat > frontend/postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# frontend/tailwind.config.ts
cat > frontend/tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss"

const config: Config = {
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-animate")],
}

export default config
EOF

# frontend/app/globals.css
cat > frontend/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

# frontend/app/layout.tsx
cat > frontend/app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'RenderFlow - AI Image Generation',
  description: 'Professional AI-powered image generation platform',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
EOF

echo "✅ Frontend files created"

# ============================================================================
# ComfyUI Workflow Files
# ============================================================================

echo "📝 Creating ComfyUI workflow templates..."

cat > comfyui/workflows/base_sdxl.json << 'EOF'
{
  "1": {
    "class_type": "CheckpointLoaderSimple",
    "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}
  },
  "3": {
    "class_type": "CLIPTextEncode",
    "inputs": {"text": "PROMPT_PLACEHOLDER", "clip": ["1", 1]}
  },
  "4": {
    "class_type": "CLIPTextEncode",
    "inputs": {"text": "low quality, blurry", "clip": ["1", 1]}
  },
  "5": {
    "class_type": "KSampler",
    "inputs": {
      "seed": -1,
      "steps": 30,
      "cfg": 7.5,
      "sampler_name": "dpmpp_2m",
      "scheduler": "karras",
      "denoise": 1.0,
      "model": ["1", 0],
      "positive": ["3", 0],
      "negative": ["4", 0],
      "latent_image": ["6", 0]
    }
  },
  "6": {
    "class_type": "EmptyLatentImage",
    "inputs": {"width": 1024, "height": 1024, "batch_size": 1}
  },
  "7": {
    "class_type": "VAEDecode",
    "inputs": {"samples": ["5", 0], "vae": ["1", 2]}
  },
  "8": {
    "class_type": "SaveImage",
    "inputs": {"images": ["7", 0], "filename_prefix": "renderflow_"}
  }
}
EOF

echo "✅ ComfyUI files created"

# ============================================================================
# Documentation Files
# ============================================================================

echo "📝 Creating documentation..."

cat > docs/API.md << 'EOF'
# RenderFlow API Documentation

## Base URL
```
http://localhost:8000
```

## Endpoints

### Health Check
```
GET /health
```

### Profiles
```
GET    /api/profiles
POST   /api/profiles
GET    /api/profiles/{id}
PUT    /api/profiles/{id}
DELETE /api/profiles/{id}
```

### Jobs
```
GET  /api/jobs
POST /api/generate-batch
GET  /api/jobs/{id}
GET  /api/jobs/{id}/images
```

### Images
```
POST /api/images/{id}/verify
GET  /api/images/{id}
```

For interactive documentation, visit `/docs` when the server is running.
EOF

cat > docs/DEPLOYMENT.md << 'EOF'
# Deployment Guide

## Quick Deploy with Docker

```bash
# 1. Clone repository
git clone https://github.com/yourusername/RenderFlow.git
cd RenderFlow

# 2. Copy and configure environment
cp .env.example .env
# Edit .env with your settings

# 3. Start services
docker-compose up -d

# 4. Access application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

## Production Deployment

See README.md for detailed production deployment instructions.
EOF

cat > docs/CONTRIBUTING.md << 'EOF'
# Contributing to RenderFlow

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Run tests
6. Submit a pull request

## Development Setup

```bash
make install
make dev
```

## Code Style

- Python: Follow PEP 8, use Black formatter
- TypeScript: Follow ESLint rules, use Prettier
- Commit messages: Use conventional commits format

## Testing

```bash
make test
```

Thank you for contributing!
EOF

echo "✅ Documentation created"

# ============================================================================
# Scripts
# ============================================================================

echo "📝 Creating utility scripts..."

cat > scripts/setup.sh << 'EOF'
#!/bin/bash
echo "🔧 RenderFlow Setup"
echo "==================="
echo ""
echo "1. Installing backend dependencies..."
cd backend && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
echo ""
echo "2. Installing frontend dependencies..."
cd ../frontend && npm install
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example files and configure"
echo "  2. Run 'make docker-up' to start all services"
EOF

chmod +x scripts/setup.sh

cat > scripts/download_models.sh << 'EOF'
#!/bin/bash
echo "📥 Downloading SDXL base model..."
cd comfyui/models/checkpoints
wget -q --show-progress https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
echo "✅ Model downloaded!"
EOF

chmod +x scripts/download_models.sh

echo "✅ Scripts created"

# ============================================================================
# Final Steps
# ============================================================================

echo ""
echo "🎉 RenderFlow repository setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Copy environment files:"
echo "     cp .env.example .env"
echo "     cp backend/.env.example backend/.env"
echo "     cp frontend/.env.example frontend/.env.local"
echo ""
echo "  2. Edit .env files with your configuration"
echo ""
echo "  3. Start the application:"
echo "     make docker-up"
echo ""
echo "  4. Access the application:"
echo "     Frontend: http://localhost:3000"
echo "     Backend:  http://localhost:8000"
echo "     API Docs: http://localhost:8000/docs"
echo ""
echo "📖 See README.md for detailed documentation"
echo ""