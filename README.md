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
