# Private Cloud Monitoring

Containerized private-cloud storage and observability platform built with Docker Compose.

## Architecture

- Nginx reverse proxy with TLS at the frontend edge (`172.20.10.0/24`)
- Nextcloud application with MariaDB and Redis on an isolated backend network (`172.20.20.0/24`)
- MinIO S3-compatible object storage on a dedicated storage network (`172.20.30.0/24`)
- Prometheus, Grafana, cAdvisor, and Node Exporter for monitoring

## Quick start

1. Copy `.env.example` to `.env` and replace every development secret.
2. Run `./setup.sh` on Linux/macOS, or `./setup.ps1` in PowerShell.
3. Start the core stack:

   ```bash
   docker compose up -d
   ```

4. Start monitoring:

   ```bash
   docker compose -f docker-compose.monitoring.yml up -d
   ```

5. Check status with `docker compose ps`.

The default development endpoints are `https://cloud.local`, Grafana at `http://localhost:3000`, and MinIO at `http://localhost:9001`. The TLS certificate is self-signed for local development.

## Security notes

- `.env` and private TLS keys are intentionally excluded from Git.
- Replace all example credentials before any shared or production deployment.
- Review the exposed ports and mount permissions for the target host.

## Project documentation

The architecture summary from the original project brief is kept in `docs/project-summary.md`.
