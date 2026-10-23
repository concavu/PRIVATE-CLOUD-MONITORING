# 🚀 Private Cloud Monitoring Platform

> A production-grade, containerized private cloud storage and observability platform built with **Docker Compose**. Designed for high availability, robust security isolation, and real-time infrastructure metrics.

---

## 🏗️ Architecture & Network Isolation

The platform is strictly segmented into dedicated Docker bridge networks to enforce security boundaries:

| Network | Subnet | Core Services | Purpose |
| :--- | :--- | :--- | :--- |
| **Frontend Edge** | `172.20.10.0/24` | Nginx (Reverse Proxy) | Handles TLS termination and entry traffic. |
| **Backend App** | `172.20.20.0/24` | Nextcloud, MariaDB, Redis | Core application logic and database caching. |
| **Storage Layer** | `172.20.30.0/24` | MinIO | S3-compatible high-performance object storage. |
| **Observability** | *Isolated* | Prometheus, Grafana, cAdvisor, Node Exporter | Real-time metrics collection and health monitoring. |

---

## ⚡ Quick Start

### Prerequisites
* **Docker & Docker Compose** installed.
* **OpenSSL** available on your system `PATH` (used for generating local TLS certificates).

### 1. Configure Environment
Clone the repository and initialize your configuration:
```bash
cp .env.example .env
(The setup script will automatically generate secure, random 64-character passwords for missing placeholders while preserving existing custom values).

2. Run Setup Script
Execute the platform initialization script depending on your OS:

Linux / macOS:

Bash
./setup.sh
Windows (PowerShell):

PowerShell
./setup.ps1
3. Deploy Stacks
Start the Core Stack (Storage & Apps):

Bash
docker compose up -d
Start the Monitoring Stack (Observability):

Bash
docker compose -f docker-compose.monitoring.yml up -d
🔍 Validation & Health Checks
Before deploying to production, validate your configuration and syntax locally:

Bash
# Validate shell scripts and Compose configurations
bash -n setup.sh scripts/*.sh
docker compose --env-file .env.example config --quiet
docker compose --env-file .env.example -f docker-compose.monitoring.yml config --quiet
Check running container statuses:

Bash
docker compose ps
docker compose -f docker-compose.monitoring.yml ps
🛡️ Security Best Practices
Zero Hardcoded Secrets: .env files and private TLS keys are strictly git-ignored.

Least Privilege Access: The MariaDB metrics exporter runs with minimal privileges (SELECT, PROCESS, REPLICATION CLIENT only).

Network Binding: Grafana is securely bound to localhost:3000 and is not exposed externally. MinIO internal API and console ports are shielded behind the Nginx reverse proxy.

📌 Access Endpoints
Main Cloud Portal: https://cloud.local (Add cloud.local to your hosts file for local development)

Grafana Dashboards: http://localhost:3000

MinIO Console: https://cloud.local/minio-console/

📂 Project Documentation
Detailed architecture documentation and system design notes can be found in the docs/project-summary.md file.

🌐 Portfolio & Contact
Explore more of my projects and technical write-ups at my personal portfolio:

👉 vu-tran-portfolio
