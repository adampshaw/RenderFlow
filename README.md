# RenderFlow

**High-volume AI Image Generation Platform | B2B Focused | ComfyUI & FastAPI Stack**

---

## 🛠️ Built With

![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![ComfyUI](https://img.shields.io/badge/ComfyUI-FF6F61?style=for-the-badge)

---

## 🧠 Project Summary

**RenderFlow** is a B2B AI image generation platform designed to automate the production, verification, and delivery of high-quality image assets.

By combining GPU-accelerated ComfyUI pipelines with human-in-the-loop verification, RenderFlow ensures rapid generation of ready-to-use image batches tailored to client specifications.  

**Core Advantage:**  
Automated, large-scale image generation with integrated verification and real-time tracking, enabling businesses to acquire professional-quality imagery at scale without manual design overhead.

---

## 🎯 Key Features

### Frontend (React / Next.js / Tailwind CSS)
- Profile management and user dashboards  
- Batch generation interface with customizable parameters  
- Image verification and quality assurance system  
- Responsive and modern UI design  

### Backend (FastAPI / Python)
- RESTful API with auto-generated documentation (Swagger/OpenAPI)  
- Integration with ComfyUI GPU worker cluster  
- Job queue management with Redis  
- S3/R2-compatible storage integration  
- WebSocket support for live updates  
- PostgreSQL ORM integration for structured data  
- Feedback loop for model improvements  

### Infrastructure & DevOps
- Docker Compose orchestration for frontend, backend, database, and ComfyUI GPU workers  
- PostgreSQL database with complete schema  
- Redis-based job queue  
- CI/CD pipeline with GitHub Actions  
- Production-ready Dockerfiles for all services  

---

## ⚙️ Technical Stack

| Layer          | Technology / Tools                         |
|----------------|--------------------------------------------|
| Frontend       | Next.js, React, Tailwind CSS               |
| Backend        | FastAPI, Python 3.10+, SQLAlchemy ORM      |
| AI Processing  | ComfyUI, GPU Cluster                       |
| Database       | PostgreSQL                                 |
| Storage        | S3 / R2                                    |
| Job Queue      | Redis                                      |
| DevOps         | Docker, Docker Compose, GitHub Actions CI/CD |

---


## 🏗️ Architecture

```text
┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│                  │         │                  │         │                  │
│  Frontend UI     │◄───────►│  FastAPI Backend │◄───────►│  ComfyUI Cluster │
│  (Next.js/React) │         │  (Python)        │         │  (GPU Workers)   │
│                  │         │                  │         │                  │
└──────────────────┘         └────────┬─────────┘         └──────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
            ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
            │  PostgreSQL   │ │  Redis Queue  │ │  AWS S3/R2    │
            │  Database     │ │  (Jobs)       │ │  (Storage)    │
            └───────────────┘ └───────────────┘ └───────────────┘
